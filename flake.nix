{
  description = "Flake configuration for my systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/b6f910a2f73fdbdcb71371dbbecd2c697a8e7c95";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    disko.url = "github:nix-community/disko/master";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    sops-nix.url = "github:mic92/sops-nix";

    # reduce duplication
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, home-manager, nix-darwin, nixpkgs, disko, pre-commit-hooks, sops-nix, ... }@inputs:
    let
      overlays = import ./overlays inputs;
      mkPkgs = system: import nixpkgs { inherit system; overlays = [ overlays ]; config.allowUnfree = true; };
      pathRoot = ./.;
      mkDarwinSystem = username: hostname: nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts
          ./hosts/darwin
          ./hosts/darwin/${hostname}
        ];

        specialArgs = {
          inherit username hostname overlays pathRoot;
        };
      };

      mkNixosSystem = username: hostname: nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts
          ./hosts/linux
          ./hosts/linux/${hostname}
        ];

        specialArgs = {
          inherit username hostname overlays pathRoot;
        };
      };

      mkHomeManagerConfig = username: system: home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        modules = [
          sops-nix.homeManagerModules.sops
          ./home
        ];
        extraSpecialArgs = {
          inherit username pathRoot;
        };
      };
    in
    (flake-utils.lib.eachDefaultSystem (system:
      let pkgs = mkPkgs system; in rec {
        inherit overlays;
        formatter = pkgs.nixpkgs-fmt;
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
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
        packages.default = packages.install-from-live;
        packages.install-from-live = pkgs.writeShellApplication {
          name = "install-from-live";
          text = ''
            if [ -z "''${1-}" ]; then
              echo "Usage: install-from-live <host-name>"
              exit 1
            fi
            nix run --experimental-features 'nix-command flakes' ${disko}#disko -- \
              -f "${self}#$1" -m destroy,format,mount --yes-wipe-all-disks && \
            nixos-install --flake "${self}#$1" --no-root-password
          '';
          meta = { description = "NixOS installation script"; };
        };

        devShells.default = pkgs.mkShell {
          inherit (checks.pre-commit-check) shellHook;
          buildInputs = checks.pre-commit-check.enabledPackages;
        };

        apps.default = {
          type = "app";
          program = "${packages.install-from-live}/bin/install-from-live";
        };
      }))
    // {
      homeConfigurations."ithinuel@nixbox" = mkHomeManagerConfig "ithinuel" "x86_64-linux";
      homeConfigurations."ithinuel@ithinuel-air" = mkHomeManagerConfig "ithinuel" "aarch64-darwin";

      darwinConfigurations.ithinuel-air = mkDarwinSystem "ithinuel" "ithinuel-air";

      nixosConfigurations.nixbox = mkNixosSystem "ithinuel" "nixbox";
    };
}
