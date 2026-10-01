{ pkgs, lib, pathRoot, config, inputs, ... }:
let
  mdadmNotify = pkgs.writeShellScriptBin "mdadm-notify" ''
    # Headless: log mdadm events to syslog instead of GUI notification.
    # TODO: Replace with something more useful (e.g. email, webhook).
    echo "mdadm: $@" >> /var/log/mdadm-events.log
  '';
  unstable_pkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in
{
  imports = [
    ./disk.nix
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/comfyui.nix"
  ];

  # ── Platform ─────────────────────────────────────────────────
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.rocmSupport = true;

  hardware = {
    enableAllFirmware = true;
    # Enable the firmware package so amdgpu.ids is on disk —
    # prevents "amdgpu: Failed to get gpu_info firmware" errors.
    firmware = [ pkgs.linux-firmware ];

    # Basic graphics + Vulkan (RADV) — required even on headless
    # for ComfyUI / Vulkan-based workloads.
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # OpenCL via ROCm runtime ICD — needed for HIP/ROCm compute.
    amdgpu.opencl.enable = true;

    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };

  users.users.ithinuel = {
    linger = true;
    # Extra groups beyond the shared defaults (networkmanager, wheel,
    # plugdev, dialout, scanner, lp, openrazer).
    extraGroups = [ "video" "render" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsXFtkro93/Ff2HtYetypL9YSi1575Q8CrDJ/xK9Yi6 ithinuel"
    ];
  };

  # ── Strix Halo GPU tuning (128 GB unified memory) ────────────
  # Per NixOS wiki: amdgpu.gttsize is deprecated.
  # Use boot.extraModprobeConfig instead.
  # GTT is demand-paged, so this is an upper bound, not a reservation.
  boot.extraModprobeConfig = ''
    # 128 GB GTT in 4 KiB pages
    options ttm pages_limit=33554432
    # 64 GB pre-allocated page pool
    options ttm page_pool_size=16777216
  '';

  # ── Boot / Secure Boot ───────────────────────────────────────
  boot = {
    kernelPackages = pkgs.linuxPackages_7_2;

    # Headless: log mdadm events to syslog.
    swraid.mdadmConf = ''
      PROGRAM ${mdadmNotify}/bin/mdadm-notify
    '';

    plymouth.enable = true;

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];

    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi = {
        efiSysMountPoint = "/boot0";
        canTouchEfiVariables = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      configurationLimit = 4;
      extraEfiSysMountPoints = [ "/boot1" ];
      autoGenerateKeys.enable = true;
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };
      measuredBoot = {
        enable = true;
        pcrs = [ 0 4 7 ];
        autoCryptenroll = {
          enable = true;
          device = "/dev/md/raid-root";
        };
      };
    };

    # Transparent ability to cross-build & run aarch64 binaries.
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      preferStaticEmulators = false;
    };
  };

  # ── SSH (headless access) ────────────────────────────────────
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── AI / Inference services ──────────────────────────────────
  services = {
    hardware.openrgb.enable = true;
    gnome.games.enable = true;

    # llama-cpp — ROCm backend (auto-detected on AMD)
    llama-cpp =
      let
        mmproj-size-counted-twice = inputs.llama-cpp-28233;
      in
      {
        enable = true;
        package = unstable_pkgs.llama-cpp.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [ mmproj-size-counted-twice ];
        });
      } // (import ./llama-cpp-config.nix);

    # Docling Serve — document parsing / OCR
    docling-serve = {
      enable = false;
      package = unstable_pkgs.docling-serve.override {
        withUI = true;
        withRapidocr = false;
        withTesserocr = false;
      };
      environment = {
        DOCLING_NUM_THREADS = "20";
        DOCLING_SERVE_OTEL_ENABLE_METRICS = "False";
        DOCLING_SERVE_OTEL_ENABLE_PROMETHEUS = "False";
      };
    };

    # ComfyUI — stable diffusion / image generation (ROCm)
    comfyui = {
      enable = false;
      package = unstable_pkgs.comfyui;
    };

    # Caddy reverse proxy
    caddy = {
      enable = true;
      openFirewall = true;
      virtualHosts = {
        "docling.home.ithinuel.me" = {
          extraConfig = ''
            tls ${pathRoot + "/certs/docling.pem"} ${config.sops.secrets.docling-key.path}
            reverse_proxy localhost:5001
          '';
        };
        "llm.home.ithinuel.me" = {
          extraConfig = ''
            tls ${pathRoot + "/certs/llm.pem"} ${config.sops.secrets.llm-key.path}
            reverse_proxy localhost:8080 {
              header_up Host localhost:8080
            }
          '';
        };
        "comfyui.home.ithinuel.me" = {
          extraConfig = ''
            tls ${pathRoot + "/certs/comfyui.pem"} ${config.sops.secrets.comfyui-key.path}
            reverse_proxy localhost:8188
          '';
        };
      };
    };
  };

  # GPU device access for docling-serve (ROCm / amdgpu)
  systemd.services.docling-serve.serviceConfig = {
    SupplementaryGroups = [ "video" "render" ];
    DeviceAllow = [
      "/dev/dri/card0 rw"
      "/dev/dri/renderD128 rw"
      "/dev/kfd rw"
    ];
  };

  # PyTorch/ROCm needs amdgpu.ids on disk — see NixOS wiki AMD_GPU.
  systemd.tmpfiles.rules = [
    "L+    /opt/amdgpu/share/libdrm/amdgpu.ids   -    -    -     -    ${pkgs.libdrm}/share/libdrm/amdgpu.ids"
  ];

  # ── Nix settings ─────────────────────────────────────────────
  sops.secrets = {
    docling-key = {
      sopsFile = pathRoot + "/secrets/ix.docling.cert-key.sops";
      format = "binary";
      owner = config.services.caddy.user;
    };
    llm-key = {
      sopsFile = pathRoot + "/secrets/ix.llm.cert-key.sops";
      format = "binary";
      owner = config.services.caddy.user;
    };
    comfyui-key = {
      sopsFile = pathRoot + "/secrets/ix.comfyui.cert-key.sops";
      format = "binary";
      owner = config.services.caddy.user;
    };
  };
  nix.settings.trusted-public-keys = [
    "tleilax-1:TnLV90m+UmVwKCmz2rqH/ED78OrHFQZ79fnKGHQfGdw="
  ];

  # ── Programs ─────────────────────────────────────────────────
  environment.systemPackages = [
    # ROCm observability
    pkgs.rocmPackages.rocminfo
    pkgs.rocmPackages.rocm-smi
    pkgs.python3Packages.amdsmi
  ];

  security = {
    pki.certificateFiles = [ "${pathRoot}/certs/home.ca.pem" ];
    sudo.wheelNeedsPassword = false;
    tpm2.enable = true;
  };
}
