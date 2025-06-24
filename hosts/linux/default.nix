{ config, pkgs, lib, hostname, username, pathRoot, ... }: {
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  networking.hostName = lib.mkDefault hostname;

  sops.secrets.password = lib.mkDefault {
    sopsFile = builtins.path { path = pathRoot + "/secrets/${username}@${hostname}.passwd"; name = "password"; };
    format = "binary";
    neededForUsers = true;
  };

  users.defaultUserShell = pkgs.zsh;
  users.groups.plugdev = { };
  users.users."${username}" = {
    hashedPasswordFile = config.sops.secrets.password.path;
    description = "Wilfried Chauveau";
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "plugdev" "dialout" ];
    packages = [ pkgs.home-manager ];
  };

  programs.gnupg.agent.enable = true;
  programs.zsh.enable = true;

  # Enable the OpenSSH daemon to ensure host SSH key to be available to sops.
  services.openssh.enable = true;

  # Enable local network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Configure console keymap
  console.keyMap = "fr-bepo";
}
