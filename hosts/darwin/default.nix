{ pkgs, username, ... }: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Creates global /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true; # Important!

  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  users.users.${username}.packages = [
    pkgs.colima
    pkgs.home-manager
  ];
}
