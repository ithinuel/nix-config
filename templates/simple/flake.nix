{
  description = "Flake configuration for my systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";

    # reduce duplication
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, utils, git-hooks, ... }:
    utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in rec {
        formatter = pkgs.nixpkgs-fmt;
        checks = {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              convco.enable = true;
              gitlint.enable = true;
              markdownlint.enable = true;
              markdownlint.settings.configuration = {
                MD013 = {
                  line_length = 100;
                  code_blocks = false;

                };
              };
            };
          };
        };
        devShells.default = pkgs.mkShell {
          inherit (checks.pre-commit-check) shellHook;
          buildInputs = checks.pre-commit-check.enabledPackages;
        };
      });
}
