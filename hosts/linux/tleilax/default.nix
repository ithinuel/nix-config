{ pkgs, lib, pathRoot, config, ... }:
let
  mdadmNotify = import ./mdadmNotify.nix { inherit lib pkgs; };
in
{
  imports = [ ./disk.nix ];

  hardware = {
    enableAllFirmware = true;
    nvidia = {
      open = true; # driver open-source officiel NVIDIA
      modesetting.enable = true; # requis pour Wayland
      powerManagement.enable = true; # recommandé
    };
    nvidia-container-toolkit.enable = true;
    bluetooth.settings.General.Experimental = true;
    saleae-logic.enable = true;
    openrazer = {
      enable = true;
      batteryNotifier.enable = true;
    };
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };
  nixpkgs.config.cudaSupport = true;
  users.users.ithinuel = {
    linger = true;
    extraGroups = [
      "scanner"
      "lp"
      "openrazer"
    ];
  };
  services = {
    hardware.openrgb.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
    gnome.games.enable = true;
  };

  boot = {
    # The rest of the RAID settings are populated by disko
    swraid.mdadmConf = ''
      PROGRAM ${mdadmNotify}
    '';

    loader = {
      # Lanzaboote currently replaces the systemd-boot module.
      # This setting is usually set to true in configuration.nix
      # generated at installation time. So we force it to false
      # for now.
      systemd-boot.enable = lib.mkForce false;
      efi = {
        # the primary boot partition
        efiSysMountPoint = "/boot0";
        # Allows the installer to modify EfiVariables (not sure why this’d be needed).
        canTouchEfiVariables = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";

      configurationLimit = 5;

      extraEfiSysMountPoints = [ "/boot1" ]; # Also install Lanzaboote on the secondary boot partition.

      # Auto generate the keys on first boot
      autoGenerateKeys.enable = true;

      # Auto enrole the key in the TPM & autoReboot to activate it
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };
    };

    # transparent ability to run cross build & run other aarch64’s binaries.
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      preferStaticEmulators = false;
    };
  };

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  sops.secrets.store-key = lib.mkDefault {
    sopsFile = pathRoot + "/secrets/tleilax.legacy-nixbox.store-key.sops";
    format = "binary";
    mode = "0400";
  };
  nix.settings = {
    secret-key-files = config.sops.secrets.store-key.path;
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "tleilax-1:TnLV90m+UmVwKCmz2rqH/ED78OrHFQZ79fnKGHQfGdw="
      "nixbox-1:+RhEM+GSeQmbFCaadAv6fQiuWzAF6f1FW4yuFhfHmYI="
    ];
  };

  programs = {
    ghidra = {
      enable = true;
      gdb = true;
      package = pkgs.ghidra.withExtensions (p: with p; [
        gnudisassembler
      ]);
    };
    pulseview.enable = true;
    steam = {
      enable = true;
      # Translates the X11 Input events into uinput events. Need for using Steam Input in Wayland.
      extest.enable = true;
    };
    coolercontrol.enable = true;
  };

  environment.systemPackages = [
    pkgs.blender
  ];

  virtualisation.virtualbox.host.enable = true;

  security.pki.certificateFiles = [ (pathRoot + "/certs/home.ca.pem") ];
  desktop.enable = true;
}
