{ overlays, ... }: {
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.warn-dirty = false;
  nix.optimise.automatic = true;

  nixpkgs.overlays = [ overlays ];
  nixpkgs.config.allowUnfree = true;
}
