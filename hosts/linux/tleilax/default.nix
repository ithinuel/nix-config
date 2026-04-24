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

  # Configure single LUKS encryption for the entire RAID array
  boot.initrd.luks.devices."root" = {
    device = "/dev/md/root";
    keyFile = "/tmp/secret.key";
    allowDiscards = true;
  };

  # Enable TPM 2.0 for fTPM auto-unlock capability
  security.tpm2.enable = true;
  security.tpm2.abrmd.enable = true;

  # Bootloader with lanzaboote for Secure Boot + measured boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  security.pki.certificateFiles = [ (pathRoot + "/certs/ithinuel.local.crt") ];
  desktop.enable = true;
}
