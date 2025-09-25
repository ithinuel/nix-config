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

  virtualisation.virtualbox.guest.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  security.pki.certificateFiles = [ (pathRoot + "/certs/ithinuel.local.crt") ];
  desktop.enable = true;
}
