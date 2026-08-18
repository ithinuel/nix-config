{
  description = "Flake configuration for my systems";

  inputs = {
    disko.url = "github:nix-community/disko/master";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.0.0";
    llm-agents.url = "github:numtide/llm-agents.nix";
    mac-app-util.url = "github:ithinuel/mac-app-util/fix/missing-icons";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    sops-nix.url = "github:mic92/sops-nix";
    utils.url = "github:numtide/flake-utils";

    gdb-dashboard.url = "github:cyrus-and/gdb-dashboard/v0.17.5";
    gdb-dashboard.flake = false;

    # reduce duplication
    disko.inputs.nixpkgs.follows = "nixpkgs";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    # llm-agents use its own nixpkgs for compatibility.
  };

  outputs = { self, utils, home-manager, nix-darwin, nixpkgs, sops-nix, ... }@inputs:
    let
      overlays = import ./overlays inputs;
      mkPkgs = system: import nixpkgs { inherit system; overlays = [ overlays ]; config.allowUnfree = true; };
      pathRoot = ./.;
      homeProfiles = {
        linux-desktop = ./home/profiles/linux-desktop.nix;
        macos-desktop = ./home/profiles/macos-desktop.nix;
        personal = ./home/profiles/personal.nix;
      };
      nixosModules.desktop = ./modules/desktop.nix;
      mkDarwinBaseSystem = username: hostname: nix-darwin.lib.darwinSystem {
        modules = [
          sops-nix.darwinModules.sops
          inputs.mac-app-util.darwinModules.default
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
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          sops-nix.nixosModules.sops
          nixosModules.desktop
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
          specialArgs = {
            inherit inputs;
          };
        };

      mkHomeManagerConfig = username: system: home-manager.lib.homeManagerConfiguration rec {
        pkgs = mkPkgs system;
        modules = [
          sops-nix.homeManagerModules.sops
          inputs.nixvim.homeModules.nixvim
          ./home/base.nix
        ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          inputs.mac-app-util.homeManagerModules.default
        ];
        extraSpecialArgs = {
          inherit username pathRoot;
        };
      };
    in
    (utils.lib.eachDefaultSystem (system:
      let pkgs = mkPkgs system; in rec {
        inherit overlays;
        formatter = pkgs.nixpkgs-fmt;
        checks = {
          pre-commit-check = inputs.git-hooks.lib.${system}.run {
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
            diskoArgs="-m mount"
            if [[ "$1" == "-f" ]]; then
              shift
              diskoArgs="-m destroy,format,mount --yes-wipe-all-disks"
            fi
            [ -z "$1" ] && { echo "Usage..."; exit 1; }
            nix run --experimental-features 'nix-command flakes' ${inputs.disko}#disko -- \
              -f "${self}#$1" "''${diskoArgs}"
            nixos-install --flake "${self}#$1" --no-root-password --no-channel-copy
          '';
          meta = { description = "NixOS installation script"; };
        };

        devShells.default = pkgs.mkShell {
          inherit (checks.pre-commit-check) shellHook;
          buildInputs = checks.pre-commit-check.enabledPackages;
        };
      }))
    // {
      inherit nixosModules;
      lib = { inherit mkNixosBaseSystem mkDarwinBaseSystem mkHomeManagerConfig homeProfiles; };
      templates = {
        simple = {
          description = "Simple template with linting & formatting for nix’s file & a devShell";
          path = ./templates/simple;
        };
      };

      homeConfigurations."ithinuel@nixbox" = mkHomeManagerConfig "ithinuel" "x86_64-linux";
      homeConfigurations."ithinuel@tleilax" = (mkHomeManagerConfig "ithinuel" "x86_64-linux").extendModules {
        modules = with homeProfiles; [ linux-desktop personal ];
        specialArgs = {
          llm-agents = inputs.llm-agents.packages."x86_64-linux";
        };
      };
      homeConfigurations."ithinuel@ithinuel-air" = (mkHomeManagerConfig "ithinuel" "aarch64-darwin").extendModules {
        modules = with homeProfiles; [ macos-desktop personal ];
        specialArgs = {
          llm-agents = inputs.llm-agents.packages."aarch64-darwin";
        };
      };

      darwinConfigurations.ithinuel-air = mkDarwinSystem "ithinuel" "ithinuel-air";

      nixosConfigurations.nixbox = mkNixosSystem "ithinuel" "nixbox";
      nixosConfigurations.tleilax = mkNixosSystem "ithinuel" "tleilax";
    };
}
