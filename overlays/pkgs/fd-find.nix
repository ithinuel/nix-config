{ lib, pkgs, stdenv, ... }: pkgs.rustPlatform.buildRustPackage rec {
  pname = "fd-find";
  version = "9.0.0";
  buildInputs = lib.optionals stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.Security ];
  src = pkgs.fetchCrate {
    inherit pname version;
    hash = "sha256-a56mn3ERyVqcGY9+y77Z3zPon1aq4nnOIcY+cnrL8rw=";
  };
  cargoHash = "sha256-3lpxsAtwTxPPoFmHAxrbdoLDyf5E/EjYcKSj0A3HbZQ";
}
