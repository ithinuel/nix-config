# My nixed Dotfiles

## Supported hosts

- `nixbox`: in VirtualBox on x86_64
- `ithinuel-air`: mac book-air M1

## Overview of Repository Structure

This repository contains my configuration files for a reproducible and modular setup using Nix.
The structure is organised as follows:

- **flake.nix / flake.lock**: The main Nix flake configuration tying together system, home-manager,
  and other configurations, ensuring reproducible builds.
- **hosts/**: Host-specific configurations (e.g. for `nixos`, `nixbox`, etc.).
- **home/**: Contains home-manager configurations and personal settings, including the Neovim
  configuration file (`neovim.vim`).
  Note: The `coc` plugin is not added using home-manager’s configuration for `neovim.coc`.
  It is added manually instead and its `coc-settings.json` file is linked out of store rather than
  locked. This is because the spellchecker plugin needs to be able do add dictionary entries it it.
- **overlays/**: Custom Nix overlays to extend or modify the default package set.

This structure is designed to simplify maintenance, allow easy customization, and ensure that each
component of my system is isolated and clearly defined.

## Install on VM

1. Start your machine with a live CD (see on [NixOS’ download page](https://nixos.org/download.html)).
2. Run the following commands in a shell:

   ```sh
   sudo nix --experimental-features 'nix-command flakes' run github:ithinuel/dotfiles <your_host_name>
   ```

3. reboot
4. After reboot, run the following command to set up the system:

   ```sh
   home-manager --flake github:ithinuel/dotfiles switch
   ```

### Why not using `disko-install` ?

During the installation process, `disko-install` relies on the current system’s store to create all
the derivations. While running from the live CD, this store does not have enough space to store it
all and the installation fails.

## Install on Darwin

- install nix: <https://nixos.org/download/#nix-install-macos>
- install nix-darwin

```sh
nix --experimental-features 'nix-command flakes'  run nix-darwin/nix-darwin-24.11 -- switch --flake github:ithinuel/dotfiles/nixed#<your_host_name>
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
