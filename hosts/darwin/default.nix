{ pkgs, username, ... }: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Creates global /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true; # Important!

  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  users.users.${username}.packages = [
    pkgs.colima
    pkgs.home-manager
  ];
}
