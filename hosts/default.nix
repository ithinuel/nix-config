{ overlays, ... }: {
  nix.settings.experimental-features = "nix-command flakes pipe-operators";
  nix.settings.warn-dirty = false;
  nix.optimise.automatic = true;

  nixpkgs.overlays = [ overlays ];
  nixpkgs.config.allowUnfree = true;
}
