{
  description = "Flake configuration for my systems";

  inputs = {
    disko.url = "github:nix-community/disko/master";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    sops-nix.url = "github:mic92/sops-nix";

    # reduce duplication
    disko.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-utils, home-manager, nix-darwin, nixpkgs, disko, git-hooks, sops-nix, nixvim, ... }@inputs:
    let
      overlays = import ./overlays inputs;
      mkPkgs = system: import nixpkgs { inherit system; overlays = [ overlays ]; config.allowUnfree = true; };
      pathRoot = ./.;
      mkDarwinBaseSystem = username: hostname: nix-darwin.lib.darwinSystem {
        modules = [
          sops-nix.darwinModules.sops
          ./hosts
          ./hosts/darwin
        ];

        specialArgs = {
          inherit username hostname overlays pathRoot;
        };
      };
      mkDarwinSystem = username: hostname:
        (mkDarwinBaseSystem username hostname).extendModules {
          modules = [
            ./hosts/darwin/${hostname}
          ];
        };
      mkNixosBaseSystem = username: hostname: nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts
          ./hosts/linux
        ];

        specialArgs = {
          inherit username hostname overlays pathRoot;
        };
      };
      mkNixosSystem = username: hostname:
        (mkNixosBaseSystem username hostname).extendModules {
          modules = [
            ./hosts/linux/${hostname}
          ];
        };

      mkHomeManagerConfig = username: system: home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        modules = [
          sops-nix.homeManagerModules.sops
          nixvim.homeManagerModules.nixvim
          ./home.nix
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
      lib = { inherit mkNixosBaseSystem mkDarwinBaseSystem mkHomeManagerConfig; };
      templates = {
        simple = {
          description = "Simple template with linting & formatting for nix’s file & a devShell";
          path = ./templates/simple;
        };
      };
      homeConfigurations."ithinuel@nixbox" = mkHomeManagerConfig "ithinuel" "x86_64-linux";
      homeConfigurations."ithinuel@ithinuel-air" = mkHomeManagerConfig "ithinuel" "aarch64-darwin";

      darwinConfigurations.ithinuel-air = mkDarwinSystem "ithinuel" "ithinuel-air";

      nixosConfigurations.nixbox = mkNixosSystem "ithinuel" "nixbox";
    };
}
