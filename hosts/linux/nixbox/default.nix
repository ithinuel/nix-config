{ lib, pathRoot, ... }: {
  imports = [
    ./disk.nix
  ];

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
