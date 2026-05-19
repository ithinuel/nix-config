# My nixed Dotfiles

## Supported hosts

- `nixbox`: NixOS in VirtualBox on x86_64
- `tleilax`: NixOS desktop on x86_64
- `ithinuel-air`: macBook Air M1

## Overview of Repository Structure

This repository contains my configuration files for a reproducible and modular setup using Nix.
The structure is organised as follows:

- **flake.nix / flake.lock**: The main Nix flake configuration tying together system, home-manager,
  and other configurations, ensuring reproducible builds.
- **hosts/**: Host-specific configurations split by platform (`darwin/`, `linux/`) with a shared
  base in `default.nix` and per-host subdirectories.
- **home/base.nix**: Base home-manager configuration applied to all hosts.
- **home/profiles/**: Optional home-manager layers (e.g. `linux-desktop`, `macos-desktop`,
  `personal`) that can be composed on top of the base. These are exported via `lib.homeProfiles`
  for downstream flakes to reuse.
- **modules/**: Reusable NixOS modules (e.g. `desktop.nix`) exported via `nixosModules` for
  downstream flakes.
- **nixvim.nix**: Neovim configuration using nixvim.
- **overlays/**: Custom Nix overlays to extend or modify the default package set.

This structure is designed to simplify maintenance, allow easy customization, and ensure that each
component of my system is isolated and clearly defined.

## Install on VM

1. Start your machine with a live CD (see on [NixOS' download page](https://nixos.org/download.html)).
2. Run the following commands in a shell:

   ```sh
   sudo nix --experimental-features 'nix-command flakes' run github:ithinuel/nix-config <your_host_name>
   ```

3. reboot
4. After reboot, run the following command to set up the system:

   ```sh
   home-manager --flake github:ithinuel/nix-config switch
   ```

### Why not using `disko-install` ?

During the installation process, `disko-install` relies on the current system’s store to create all
the derivations. While running from the live CD, this store does not have enough space to store it
all and the installation fails.

## Install on Darwin

- install nix: <https://nixos.org/download/#nix-install-macos>
- install nix-darwin

```sh
nix --experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-25.11 -- switch --flake github:ithinuel/nix-config#<your_host_name>
```

## Maintenance

From time to time it’s good to clean up the store. For this a few commands come in handy:

- `nixos-rebuild --flake $flake list-generations`: lists the generation (found in grub)
  Unwanted generations can be removed with `sudo rm /nix/var/nix/profiles/system-<gen>-link`.  
  Then run `nixos-rebuild --flake $flake switch` to force an update of the grub menu.
- `home-manager --flake $flake generations` and  
  `home-manager --flake $flake expire-genrations <some duration>` to remove unwanted generations.
- `nix profile wipe-history` to get rid of old profiles.
- `nix store gc` to remove all unused packages from the store.
