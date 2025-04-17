{ config, pkgs, lib, hostname, username, pathRoot, ... }: {
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.networkmanager.enable = true;
  networking.hostName = lib.mkDefault hostname;

  environment.shells = [ pkgs.zsh ];

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
  programs.dconf = {
    enable = pkgs.stdenv.isLinux;
    # A "user" profile with a database
    profiles.user.databases = [{
      settings = import ./dconf.nix lib;
    }];
  };


  # Enable docker for users
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Enable the OpenSSH daemon to ensure host SSH key to be available to sops.
  services.openssh.enable = true;

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = username;

  # make udev map debug probes to plugdev
  services.udev.packages = [ pkgs.picoprobe-udev-rules ];
  services.gvfs.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "bepo_afnor";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
