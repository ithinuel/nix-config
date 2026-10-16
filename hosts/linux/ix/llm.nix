{ pkgs, lib, username, inputs, ... }:
let
  unstable_pkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  # llama-swap listens on 8080; Caddy proxies llm.home.ithinuel.me -> localhost:8080.
  port = 8080;

  # llama.cpp router server; llama-swap proxies the llama.cpp model ids to it.
  routerPort = 8081;

  # The llama-swap unit's StateDirectory; see the service overrides below.
  # Named strata-data after the engine it was created for; kept as-is so the
  # model data on ix does not need migrating.
  dataDir = "/var/lib/strata-data";

  # Gufo — Strix Halo engine serving Flash-Next. The release output is the
  # tagged-build package; mkGufoServe renders the `gufo serve` command line.
  # port = "\${PORT}" is passed through raw (mk-serve.nix treats $-prefixed
  # strings as env-var substitutions), which is how llama-swap assigns the port.
  gufoPkg = inputs.gufo.packages.x86_64-linux.release;
  gufoServe = inputs.gufo.lib.mkGufoServe;

  # The mmproj-size-counted-twice fix (llama.cpp PR 28233) is not upstream yet, so the
  # router runs this override of nixpkgs' ROCm build.
  llamaServer = pkgs.llama-cpp.overrideAttrs {
    patches = [ inputs.llama-cpp-28233 ];
  };

  # The llama.cpp router presets — services.llama-cpp.modelsPreset below; the module
  # converts them to an INI file fed to --models-preset. Keys are the model ids clients
  # use; inner keys are llama-server argument names. Note llama-server canonicalizes the
  # section name's quant tag (repo:UD-Q8_K_XL -> repo:Q8_K_XL), so the UD- presets carry
  # an explicit alias for the full id — that is what llama-swap forwards. (gemma's id is
  # already canonical; aliasing it to itself would conflict.)
  modelsPreset = {
    "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q4_K_XL" = {
      hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q4_K_XL";
      temperature = 0.6;
      top-p = 0.95;
      top-k = 20;
      min-p = 0.0;
      presence-penalty = 0.0;
      repeat-penalty = 1.0;
      flash-attn = "on";

      # This causes the model to spiral in thinking loops.
      #chat-template-kwargs = "{\"preserve_thinking\": \"true\"}";

      # enable MTP
      spec-type = "draft-mtp,ngram-mod";
      spec-draft-n-max = 5;
      # MTP + ngram-mod with p-min for creative long-form
      spec-draft-p-min = 0.75;

      cache-type-k = "q8_0";
      cache-type-v = "q8_0";

      # enable 1M context with RoPE
      rope-scaling = "yarn";
      rope-scale = 4;
      yarn-orig-ctx = 256 * 1024;
      ctx-size = 1024 * 1024;
    };

    # Champion: UD-Q4_K_XL + K+V q4_0 KV + draft-mtp,ngram-mod n=12/n-min=24
    # Speed: cold 59.7 tok/s | prose 11-14 | code 30-40 | tpt 7.9-14.3s/task
    # Context: 1M via yarn (262k is the measured sweet spot, yarn available for long docs)
    "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL" = {
      hf-repo = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";

      temp = 1.0;
      top-p = 0.95;
      top-k = 20;
      min-p = 0;
      presence-penalty = 0.0;
      repeat-penalty = 1.0;

      # Context: 256K native (no yarn — repo's 262k needle-exact ceiling).
      # KV cache: q4_0 (saves ~4.3GB vs f16, no quality loss).
      cache-type-k = "q4_0";
      cache-type-v = "q4_0";
      ctx-size = 256 * 1024;

      # Speculative decoding: MTP + ngram-mod (measured champion, stacked losslessly)
      # n-max=12 is peak (n16 regresses); n-min=24 is plateau
      # Time-per-task: 7.9-14.3s (median 11.3), 15/15 correct
      # +27% long-form/storytelling at ~10% code cost
      # Mechanism: truncates low-confidence MTP drafts -> better acceptance on diverse text
      spec-type = "draft-mtp,ngram-mod";
      spec-draft-n-max = 12;
      # MTP + ngram-mod with p-min for creative long-form
      spec-draft-p-min = 0.75;

      # Rollback when MTP prediction is rejected
      ctx-checkpoints = 8;
      checkpoint-min-step = 32768;

      # Thinking is a hard-lane, not default (byte-stable prefix = 160x TTFT)
      reasoning = "off";

      # Flash attention on (required on ROCm/gfx1151)
      flash-attn = "on";

      # Thread count (CPU threads are not the bottleneck at full GPU offload)
      threads = 16;
      spec-ngram-mod-n-min = 24;
    };

    "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL" = {
      hf-repo = "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL";
      spec-type = "draft-mtp";
      spec-draft-n-max = 2;
      temp = 1.0;
      top-p = 0.95;
      top-k = 64;
      ctx-size = 256 * 1024;
    };
  };
in
{
  # ── llama.cpp router server ────────────────────────────────────
  # One llama-server hosting all preset models: loads on demand, keeps --models-max
  # loaded and unloads after --sleep-idle-seconds idle. Besides the preset ids, the
  # LLAMA_CACHE scan registers the cached GGUFs under their bare-quant ids
  # (repo:Q8_K_XL & co.), which stay reachable on :8081 only.
  services.llama-cpp = {
    enable = true;
    package = llamaServer;
    port = routerPort; # host defaults to 127.0.0.1
    inherit modelsPreset;
    extraFlags = [ "--models-max" "2" "--sleep-idle-seconds" "1800" ];
  };

  # Strix Halo ROCm env (HSA_ENABLE_SDMA=0: kernel-hang guard under GTT pressure on UMA;
  # HSA_XNACK=1: correct memory-fault semantics for GTT pages — see
  # KyaniteLabs/qwen38-27b-strix-halo).
  systemd.services.llama-cpp.environment = {
    HSA_ENABLE_SDMA = "0";
    HSA_XNACK = "1";
  };

  # ── llama-swap — the single endpoint ─────────────────────────────
  # Spawns Gufo on demand and proxies the llama.cpp model ids to the router above.
  # The nixpkgs module generates the YAML config from settings.

  services.llama-swap = {
    enable = true;
    # llama-swap — the persistent activity store (settings.store.path in llm.nix) needs
    # >=236; nixos-26.05 pins 224. The rest of the service stays in llm.nix.
    package = unstable_pkgs.llama-swap;
    listenAddress = "127.0.0.1";
    inherit port;
    settings = {
      healthCheckTimeout = 300;

      # Activity log in a file-backed SQLite DB: request counts and token usage survive
      store.path = "${dataDir}/llama-swap.sqlite";

      models = {
        # Flash-Next on the GGUF shards under dataDir (MTP head fetched under the model
        # dir). /ready gates on model load, unlike /health which is liveness-only.
        # servedModelName must match the llama-swap id: gufo 404s unknown model names.
        # sessions 2 until the 262k-context admission reservation is measured; raise
        # if memory allows.
        "unsloth/Qwen3.8-Flash-Next-GGUF:Q4_K_XL" = {
          cmd = gufoServe {
            gufo = gufoPkg;
            port = "\${PORT}";
            model = "${dataDir}/models/unsloth-UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
            speculative = "mtp";
            mtpModel = "${dataDir}/models/unsloth-UD-Q4_K_XL/MTP/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";
            servedModelName = "unsloth/Qwen3.8-Flash-Next-GGUF:Q4_K_XL";
            sessions = 2;
            context = 262144;
            # Per-model dir: Flash-Next locks its cache dir and deletes foreign files in it.
            cacheDisk = "${dataDir}/gufo-cache/flash-next";
          };
          checkEndpoint = "/ready";
          ttl = 1800;
        };
      }
      # The router serves every preset id itself and loads/evicts on its own schedule,
      # so llama-swap just forwards — no per-model process, ttl or env here.
      // lib.mapAttrs (_name: _preset: { proxy = "http://127.0.0.1:${toString routerPort}"; }) modelsPreset;
    };
  };

  # Deviations from the module's unit: it runs a hardened DynamicUser, but the Gufo
  # engine it spawns needs ithinuel's video/render groups for /dev/kfd and write access
  # to the model data and engine log under the StateDirectory. (KillMode=control-group,
  # under which the gufo server SIGTERMs its engine, is the systemd default.)
  systemd.services.llama-swap = {
    after = [
      "network-online.target"
      "systemd-userdbd.service"
      "llama-cpp.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      # ithinuel: video/render for /dev/kfd (ROCm), and owner of dataDir.
      User = username;
      DynamicUser = lib.mkForce false;
      # ProtectSystem=strict (module): dataDir is the only writable home for the
      # model data and the engine log.
      StateDirectory = "strata-data";
      WorkingDirectory = lib.mkForce dataDir;
      # ROCm needs W+X mappings (HSA/JIT), which MemoryDenyWriteExecute forbids, and
      # real supplementary groups on /dev/kfd, which PrivateUsers strips.
      MemoryDenyWriteExecute = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };
}
