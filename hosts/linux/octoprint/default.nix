{ config, pkgs, lib, inputs, pathRoot, username, ... }:
{
  imports = [
    # Boot chain and image layout for the Pi: a firmware partition with
    # config.txt and u-boot, extlinux on top of the ext4 root.
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    inputs.nixos-hardware.nixosModules.raspberry-pi-3
  ];

  # sd-image pulls in profiles/all-hardware, which asks for kernel modules this
  # board has no use for; nixos-hardware’s raspberry-pi-3 module adds exactly
  # what the Pi does need.
  disabledModules = [ "profiles/all-hardware.nix" ];
  hardware.enableAllHardware = lib.mkForce false;

  nixpkgs.hostPlatform = "aarch64-linux";

  boot.zfs.forceImportRoot = false;

  # ── Secrets ────────────────────────────────────────────────────
  sops.secrets.wpa = {
    sopsFile = pathRoot + "/secrets/octoprint.wpa.enc.txt";
    format = "binary";
    group = "wpa_supplicant";
    mode = "0640";
  };

  sops.secrets.octoprint-cert-key = {
    sopsFile = pathRoot + "/secrets/octoprint.cert-key.enc.pem";
    format = "binary";
    owner = config.services.caddy.user;
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # ── Network ────────────────────────────────────────────────────
  networking.useDHCP = true;

  networking.wireless = {
    enable = true;
    secretsFile = config.sops.secrets.wpa.path;
    networks.OurHome.pskRaw = "ext:OurHome";
  };

  services.avahi = {
    ipv4 = true;
    publish = {
      enable = true;
      domain = true;
      userServices = true;
    };
  };

  # ── OctoPrint behind Caddy ─────────────────────────────────────
  services.octoprint = {
    enable = true;
    port = 5000;
    extraConfig.server.cookies.secure = true;
    plugins = plugins: with plugins; [
      # PrusaLevelingGuide
      # cancelobject
      costestimation
      # filemanager
      # firmwareupdater
      gcodeeditor
      marlingcodedocumentation
      # prusa_mini_eta
      themeify
      # timelapseplus
    ];
  };

  services.caddy = {
    enable = true;
    openFirewall = true; # tcp 80 + 443, udp 443 for HTTP/3

    extraConfig = ''
      (octoprint) {
        tls ${pathRoot + "/certs/octoprint.pem"} ${config.sops.secrets.octoprint-cert-key.path}
        reverse_proxy 127.0.0.1:${toString config.services.octoprint.port}
      }
    '';

    virtualHosts."octoprint.home.ithinuel.me".extraConfig = "import octoprint";
    virtualHosts."octoprint.local".extraConfig = "import octoprint";
  };

  # ── Access ─────────────────────────────────────────────────────
  users.users."${username}" = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsXFtkro93/Ff2HtYetypL9YSi1575Q8CrDJ/xK9Yi6 ithinuel@tleilax"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKoClo3Pe8KKa+hpWmMvuYYR13ctiDqvvpTOOatx17UF ithinuel@ithinuel-air"
    ];
  };

  nix.settings.trusted-public-keys = [
    "tleilax-1:TnLV90m+UmVwKCmz2rqH/ED78OrHFQZ79fnKGHQfGdw="
  ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];
}
