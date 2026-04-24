{ lib, pathRoot, config, ... }: {
  imports = [
    ./disk.nix
  ];

  sops.secrets.store-key = lib.mkDefault {
    sopsFile = pathRoot + "/secrets/nixbox.store-key.sops";
    format = "binary";
    mode = "0400";
  };
  nix.settings.secret-key-files = config.sops.secrets.store-key.path;
  nix.settings.trusted-public-keys = [ "nixbox-1:+RhEM+GSeQmbFCaadAv6fQiuWzAF6f1FW4yuFhfHmYI=" ];

  virtualisation.virtualbox.guest.enable = false;

  # Enable RAID for disk redundancy
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    ARRAY /dev/md/root metadata=1.2
  '';

  # Enable TPM 2.0 for fTPM auto-unlock capability
  security.tpm2.enable = true;
  security.tpm2.abrmd.enable = true;

  # Bootloader with lanzaboote for Secure Boot + measured boot
  boot = {
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

    initrd = {
      # Required for measured boot
      systemd.enable = true;

      # Configure single LUKS encryption for the entire RAID array
      luks.devices."root" = {
        device = "/dev/md/root";
        keyFile = "/tmp/secret.key";
        allowDiscards = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      settings = {
        extraEfiSysMountPoints = [ "/boot1" ]; # Also install Lanzaboote on the secondary boot partition.

        # Auto generate the keys on first boot
        autoGenerateKeys.enable = true;
        # Auto enrole the key in the TPM & autoReboot to activate it
        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
        };

        # Enable measured boot (to auto unlock the LUKS volume)
        # Needs call to systemd-cryptenroll, make sure to enroll with a pin too for added security.
        measuredBoot = {
          enable = true;
          pcrs = [
            0 # SRTM, BIOS, Host Platform extensions, Embedded Option ROMs and PI Drivers
            4 # UEFI Boot Manager Code and Boot Attempts
            7 # Secure Boot Policy
          ];
        };
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  security.pki.certificateFiles = [ (pathRoot + "/certs/ithinuel.local.crt") ];
  desktop.enable = true;
}
