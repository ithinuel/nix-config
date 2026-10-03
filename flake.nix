{
  description = "Flake configuration for my systems";

  inputs = {
    disko.url = "github:nix-community/disko/master";
    git-hooks.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.2.0";
    llm-agents.url = "github:numtide/llm-agents.nix";
    mac-app-util.url = "github:ithinuel/mac-app-util/fix/missing-icons";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-26.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    sops-nix.url = "github:mic92/sops-nix";
    utils.url = "github:numtide/flake-utils";
    treefmt.url = "github:numtide/treefmt-nix";

    llama-cpp-28233.url = "https://github.com/ggml-org/llama.cpp/commit/c94e58d21f7c773f7fb772e6041d81f4aac252d5.patch";
    llama-cpp-28233.flake = false;

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
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
    # llm-agents use its own nixpkgs for compatibility.
  };

  outputs = { self, utils, home-manager, nix-darwin, nixpkgs, sops-nix, ... }@inputs:
    let
      overlays = import ./overlays inputs;
      pathRoot = ./.;
      homeProfiles = {
        linux-desktop = ./home/profiles/linux-desktop.nix;
        macos-desktop = ./home/profiles/macos-desktop.nix;
        personal-desktop = ./home/profiles/personal-desktop.nix;
        base-desktop = ./home/profiles/base-desktop.nix;
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
          inherit username hostname overlays pathRoot inputs;
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
          inherit username hostname overlays pathRoot inputs;
        };
      };
      mkNixosSystem = username: hostname:
        (mkNixosBaseSystem username hostname).extendModules {
          modules = [
            ./hosts/linux/${hostname}
          ];
        };

      mkHomeManagerConfig = username: system: home-manager.lib.homeManagerConfiguration rec {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ overlays ];
          }
          sops-nix.homeManagerModules.sops
          inputs.nixvim.homeModules.nixvim
          ./home/base.nix
        ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          inputs.mac-app-util.homeManagerModules.default
        ];
        extraSpecialArgs = {
          inherit username pathRoot inputs;
        };
      };
    in
    (utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        skip_wip = ''
          msg=$(head -n 1 "$1")
          if [[ "$msg" =~ ^(--wip--|fixup) ]]; then
            exit 0
          fi
        '';
        inherit (pkgs) lib;
      in
      rec {
        inherit overlays;
        formatter = inputs.treefmt.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs.nixpkgs-fmt.enable = true;
        };
        checks = {
          pre-commit-check = inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # Nix
              convco = {
                enable = true;
                entry = "${pkgs.writeShellScript "convco-skip-wip" ''
                  ${skip_wip}
                  cat "$1" | ${lib.getExe pkgs.convco} check --from-stdin
                ''}";
              };
              gitlint = {
                enable = true;
                entry = "${pkgs.writeShellScript "gitlint-skip-wip" ''
                  ${skip_wip}
                  ${pkgs.lib.getExe pkgs.gitlint} --staged --ignore WIP --msg-filename $1
                ''}";
              };

              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              statix.enable = true;
              markdownlint = {
                enable = true;
                settings.configuration.MD013 = {
                  line_length = 100;
                  code_blocks = false;
                };
              };
            };
          };
        };
        packages = rec {
          default = install-from-live;
          install-from-live = pkgs.writeShellApplication {
            name = "install-from-live";
            text = ''
              diskoArgs="-m mount"
              if [[ "$1" == "-f" ]]; then
                shift
                diskoArgs="-m destroy,format,mount --yes-wipe-all-disks"
              fi
              [ -z "$1" ] && { echo "Usage..."; exit 1; }
              # shellcheck disable=SC2086
              nix run --experimental-features 'nix-command flakes' ${inputs.disko}#disko -- \
                -f "${self}#$1" ''${diskoArgs}
              nixos-install --flake "${self}#$1" --no-root-password --no-channel-copy
            '';
            meta = { description = "NixOS installation script"; };
          };
        };

        devShells.default = pkgs.mkShell {
          inherit (checks.pre-commit-check) shellHook;
          buildInputs = checks.pre-commit-check.enabledPackages;
        };
      }))
    // {
      inherit nixosModules;
      lib = { inherit mkNixosBaseSystem mkDarwinBaseSystem mkHomeManagerConfig homeProfiles; };
      overlays.default = overlays;
      templates = {
        simple = {
          description = "Simple template with linting & formatting for nix’s file & a devShell";
          path = ./templates/simple;
        };
      };

      homeConfigurations."ithinuel@ix" = (mkHomeManagerConfig "ithinuel" "x86_64-linux").extendModules {
        modules = [
          { nixpkgs.config = { rocmSupport = true; }; }
          homeProfiles.personal
        ];
      };
      homeConfigurations."ithinuel@tleilax" = (mkHomeManagerConfig "ithinuel" "x86_64-linux").extendModules {
        modules = [
          { nixpkgs.config = { cudaSupport = true; }; }
        ] ++ (with homeProfiles; [
          base-desktop
          linux-desktop
          personal-desktop
          personal
        ]);
      };
      homeConfigurations."ithinuel@ithinuel-air" = (mkHomeManagerConfig "ithinuel" "aarch64-darwin").extendModules {
        modules = (with homeProfiles; [
          base-desktop
          macos-desktop
          personal-desktop
          personal
        ]) ++ [
          {
            programs.ssh = {
              enable = true;
              enableDefaultConfig = false;
              settings.tleilax.ForwardAgent = "yes";
            };
          }
        ];
      };

      darwinConfigurations.ithinuel-air = mkDarwinSystem "ithinuel" "ithinuel-air";

      nixosConfigurations.tleilax = mkNixosSystem "ithinuel" "tleilax";
      nixosConfigurations.ix = mkNixosSystem "ithinuel" "ix";
    };
}
