{ pkgs, lib, username, inputs, ... }:
let
  unstable_pkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  # Caddy fronts llama-swap as llm.home.ithinuel.me.
  port = 8080;

  # Runtime state: sqlite activity store, Gufo disk cache, engine logs.
  # Model bytes are read straight from the Nix store.
  dataDir = "/var/lib/strata-data";

  # Gufo — Strix Halo engine, serves Flash-Next.
  gufoPkg = inputs.gufo.packages.x86_64-linux.release;
  gufoServe = inputs.gufo.lib.mkGufoServe;

  llamaServerExe = lib.getExe' pkgs.llama-cpp "llama-server";

  # nix-hug fetchModels pins: every weight is a store path, deduplicated
  # across repos and never re-fetched behind our back.
  nixHug = inputs.nix-hug.lib.${pkgs.stdenv.hostPlatform.system};

  # Fetches exactly the files listed under `files` and returns the pin's store
  # path with `files` attached for the engines below. Refresh a pin with:
  #   nix run github:eordano/nix-hug -- fetch <repo> --ref <rev> --file <path> [--file …]
  # then paste rev/fileTreeHash/gitRepoHash in and re-check `files`.
  mkPin = { repoId, rev, fileTreeHash, gitRepoHash, files }:
    (nixHug.fetchModel {
      inherit repoId rev fileTreeHash gitRepoHash;
      filters.files =
        if files ? shards then files.shards ++ [ files.mtp files.mmproj ]
        else [ files.model ] ++ lib.optionals (files ? mmproj) [ files.mmproj ]
        ++ lib.optionals (files ? mtp) [ files.mtp ];
    })
    // {
      inherit files;
    };

  # Engines render a model block into a llama-swap entry: one process bound to
  # the ${PORT} llama-swap substitutes at spawn, keyed by the block's id. No
  # ttl — models stay resident until the matrix evicts them or
  # POST /api/models/unload frees them by hand.
  llamaEngine = { id, drv, args }: {
    cmd = lib.concatStringsSep " " (
      [
        llamaServerExe
        "--host 127.0.0.1"
        "--port \${PORT}"
        # without this llama-server names the model after the store path
        "--alias ${lib.escapeShellArg id}"
        "--model ${lib.escapeShellArg "${drv}/${drv.files.model}"}"
      ]
      ++ lib.optionals (drv.files ? mmproj) [
        "--mmproj ${lib.escapeShellArg "${drv}/${drv.files.mmproj}"}"
      ]
      # quants without MTP layers (gemma) speculate with an external head
      ++ lib.optionals (drv.files ? mtp) [
        "--model-draft ${lib.escapeShellArg "${drv}/${drv.files.mtp}"}"
      ]
      ++ lib.mapAttrsToList (k: v: "--${k} ${lib.escapeShellArg (toString v)}") args
    );
  };

  # Gufo serves the first shard (siblings are picked up next to it) and
  # speculates with the MTP head when the pin carries one. /ready waits for the
  # model load, unlike liveness-only /health; servedModelName must match the
  # llama-swap id.
  gufoEngine = { id, drv, args }: {
    cmd = gufoServe (
      {
        gufo = gufoPkg;
        port = "\${PORT}";
        model = "${drv}/${builtins.head drv.files.shards}";
        servedModelName = id;
      }
      // args
      // lib.optionalAttrs (drv.files ? mtp) {
        speculative = "mtp";
        mtpModel = "${drv}/${drv.files.mtp}";
      }
    );
    checkEndpoint = "/ready";
  };

  # Each block becomes its own llama-swap model, keyed by the id clients use.
  modelsPreset = {
    "unsloth/Qwen3.5-9B-GGUF:Q4_K_XL" = {
      engine = llamaEngine;
      drv = mkPin {
        repoId = "unsloth/Qwen3.5-9B-GGUF";
        rev = "3885219b6810b007914f3a7950a8d1b469d598a5";
        fileTreeHash = "sha256-TPR749YkoRQdtGvbahWLsiqZiivsUf5DhhfLpa6UeyI=";
        gitRepoHash = "sha256-DgRqlM3pDsUyqGNM0CZDxXXTEP/BjmdW9XsqGk0Jnu8=";
        files = {
          model = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
          mmproj = "mmproj-BF16.gguf";
        };
      };
      args = {
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";

        # fit_params would auto-size the KV cache to fill all memory at load
        # time — permanent without ttl, and load-order dependent.
        ctx-size = 128 * 1024;
      };
    };

    "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL" = {
      engine = llamaEngine;
      drv = mkPin {
        repoId = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
        rev = "5bc3e238d916f48a861bac2f8a1990a0e9b7e98d";
        fileTreeHash = "sha256-8gC7LFtwlOU5egKZd0KLhWskeezaMXgUJO0nJM5mSNQ=";
        gitRepoHash = "sha256-BfJBPMKRsqJjKiK7f21g0Lb9xZZXjdRuIIXDZbLCZso=";
        files = {
          model = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
          mmproj = "mmproj-BF16.gguf";
        };
      };
      args = {
        temperature = 0.6;
        top-p = 0.95;
        top-k = 20;
        min-p = 0.0;
        presence-penalty = 0.0;
        repeat-penalty = 1.0;
        flash-attn = "on";

        # chat-template-kwargs preserve_thinking=true makes the model spiral
        # into thinking loops — do not re-enable.

        # MTP + ngram-mod; p-min favors creative long-form.
        spec-type = "draft-mtp,ngram-mod";
        spec-draft-n-max = 5;
        spec-draft-p-min = 0.75;

        cache-type-k = "q8_0";
        cache-type-v = "q8_0";

        # yarn scaling to 1M ctx
        rope-scaling = "yarn";
        rope-scale = 4;
        yarn-orig-ctx = 256 * 1024;
        ctx-size = 1024 * 1024;
      };
    };

    # Champion config from https://github.com/KyaniteLabs/qwen38-27b-strix-halo.
    "unsloth/Qwen3.8-27B-GGUF:Q4_K_XL" = {
      engine = llamaEngine;
      drv = mkPin {
        repoId = "unsloth/Qwen3.8-27B-GGUF";
        rev = "4ca720788d1e01f1bff70c033e0d0028fd02e502";
        fileTreeHash = "sha256-N7PVnYrXCvB05t4xsTZZF6CdSCitgJZa3QQNMDCqrcc=";
        gitRepoHash = "sha256-eY/zo6QuryVdt2S58qmtehKna92ogQvklTLr6ALXpXA=";
        files = {
          model = "Qwen3.8-27B-UD-Q4_K_XL.gguf";
          mmproj = "mmproj-BF16.gguf";
        };
      };
      args = {
        temp = 1.0;
        top-p = 0.95;
        top-k = 20;
        min-p = 0;
        presence-penalty = 0.0;
        repeat-penalty = 1.0;

        # q4_0 KV saves ~4.3 GB vs f16 with no quality loss; 256K is the
        # native ceiling (no yarn — 262k is needle-exact).
        cache-type-k = "q4_0";
        cache-type-v = "q4_0";
        ctx-size = 256 * 1024;

        # ngram-mod stacks on MTP; n-max 12 is peak (16 regresses), n-min 24
        # is a plateau: ~10% code speed traded for long-form gains.
        spec-type = "draft-mtp,ngram-mod";
        spec-draft-n-max = 12;
        spec-draft-p-min = 0.75;

        # rollback when an MTP prediction is rejected
        ctx-checkpoints = 8;
        checkpoint-min-step = 32768;

        # thinking is opt-in: a byte-stable prefix keeps TTFT low
        reasoning = "off";

        # required on ROCm/gfx1151
        flash-attn = "on";

        threads = 16;
        spec-ngram-mod-n-min = 24;
      };
    };

    "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL" = {
      engine = llamaEngine;
      drv = mkPin {
        repoId = "unsloth/gemma-4-26B-A4B-it-GGUF";
        rev = "c099eb48e663fd284577b04978a94ffccb261841";
        fileTreeHash = "sha256-jdA4eUtIUzNU/DrmnM3U6Wai/saA3dZWTHAwEIE5Xnk=";
        gitRepoHash = "sha256-c3/0V/QY3UtFFJag9jIo66i6z082Z2VQtCTe74E3vCw=";
        files = {
          model = "gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf";
          mmproj = "mmproj-BF16.gguf";
          # no MTP layers in the quant; draft-mtp needs this external head
          mtp = "MTP/mtp-gemma-4-26B-A4B-it-Q8_0.gguf";
        };
      };
      args = {
        spec-type = "draft-mtp";
        spec-draft-n-max = 2;
        temp = 1.0;
        top-p = 0.95;
        top-k = 64;
        ctx-size = 256 * 1024;
      };
    };

    # Flash-Next on Gufo: 4 shards + the shared Q8_0 MTP head; mmproj is
    # pinned for future use. cacheDisk must be per-model — Gufo locks its dir
    # and deletes foreign files in it.
    "unsloth/Qwen3.8-Flash-Next-GGUF:Q4_K_XL" = {
      engine = gufoEngine;
      drv = mkPin {
        repoId = "unsloth/Qwen3.8-Flash-Next-GGUF";
        rev = "38bb39ee97821de2c9009abb7e93950eec396e66";
        fileTreeHash = "sha256-ZjHP3wJwSxZ4K+/EESkSWEYLeI9efwAlrVqn1grv3mM=";
        gitRepoHash = "sha256-lHr0+/CGLFgJRZCywowkWHARUpmakSqd6VbE2N52wGE=";
        files = {
          shards = [
            "UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf"
            "UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00002-of-00004.gguf"
            "UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00003-of-00004.gguf"
            "UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00004-of-00004.gguf"
          ];
          mtp = "MTP/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";
          mmproj = "mmproj-BF16.gguf";
        };
      };
      args = {
        # raise once the 262k-context admission reservation is measured
        sessions = 2;
        context = 262144;
        cacheDisk = "${dataDir}/gufo-cache/flash-next";
      };
    };
  };

  # A model block's key is the llama-swap id; the engine gets it as the
  # served model name and renders the entry.
  presetToEntry = id: { drv, engine, args }: engine { inherit id drv args; };

  llamaSwapModels = lib.mapAttrs' (id: b: lib.nameValuePair id (presetToEntry id b)) modelsPreset;
in
{
  # ── llama-swap — the single endpoint ─────────────────────────
  # Spawns the per-model engines on demand; the matrix router decides
  # co-residency and eviction. The nixpkgs module renders the YAML config and
  # validates it (llama-swap -validate) at build time.

  services.llama-swap = {
    enable = true;
    # store.path needs llama-swap >=236; nixos-26.05 pins 224
    # llama-swap 263 implemented a gufoProbe to gather the model’s metadata.
    package = unstable_pkgs.llama-swap.overrideAttrs (_final: prev: {
      version = "265";
      src = prev.src.overrideAttrs (_: {
        hash = "sha256-8NIsLxYTxax0q1uMwwh2W8nQwBUpY05Cqophr+LTdOQ=";
      });
    });
    listenAddress = "127.0.0.1";
    inherit port;
    settings = {
      healthCheckTimeout = 300;

      # request counts and token usage survive restarts
      store.path = "${dataDir}/llama-swap.sqlite";

      models = llamaSwapModels;

      routing.router = {
        use = "matrix";
        settings.matrix = {
          vars = {
            qw35 = "unsloth/Qwen3.5-9B-GGUF:Q4_K_XL";
            qw36 = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL";
            qw3827 = "unsloth/Qwen3.8-27B-GGUF:Q4_K_XL";
            gemma = "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL";
            qw38FN = "unsloth/Qwen3.8-Flash-Next-GGUF:Q4_K_XL";
          };
          # cold-start cost weights: Gufo loads slowest, then 27B
          evict_costs = {
            qw38FN = 50;
            qw3827 = 30;
          };
          # A model outside every set can only run alone, so gemma requests
          # evict the hot combo. The two qw36 variants share weights, so only
          # one appears in a set — the other evicts instead of double-resident.
          sets = {
            code_and_docs = "(qw35 & (qw36 | qw3827 | gemma)) | qw38FN";
          };
        };
      };
    };
  };

  # ROCm env for the spawned engines, per KyaniteLabs/qwen38-27b-strix-halo:
  # SDMA guard against kernel hangs under GTT pressure on UMA; XNACK for
  # correct memory-fault semantics on GTT pages.
  systemd.services.llama-swap.environment = {
    HSA_ENABLE_SDMA = "0";
    HSA_XNACK = "1";
  };

  # The module's unit is hardened (DynamicUser); the engines it spawns need
  # ithinuel's video/render groups for /dev/kfd and write access to dataDir,
  # plus W+X mappings (ROCm HSA/JIT) and real supplementary groups — hence
  # MemoryDenyWriteExecute and PrivateUsers are dropped.
  systemd.services.llama-swap = {
    after = [
      "network-online.target"
      "systemd-userdbd.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = username;
      DynamicUser = lib.mkForce false;
      StateDirectory = "strata-data";
      WorkingDirectory = lib.mkForce dataDir;
      MemoryDenyWriteExecute = lib.mkForce false;
      PrivateUsers = lib.mkForce false;
    };
  };
}
