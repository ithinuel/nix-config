{ pkgs, lib, pathRoot, config, ... }:
let
  mdadmNotify =
    let
      # binaries
      date = lib.getExe' pkgs.coreutils "date";
      id = lib.getExe' pkgs.coreutils "id";
      sort = lib.getExe' pkgs.coreutils "sort";
      who = lib.getExe' pkgs.coreutils "who";
      awk = lib.getExe pkgs.gawk;
      notifySend = lib.getExe pkgs.libnotify;
      sudo = lib.getExe' pkgs.sudo "sudo";
      systemdCat = lib.getExe' pkgs.systemd "systemd-cat";
    in
    pkgs.writeShellScript "mdadm-notify" ''
      # mdadm calls: PROGRAM <event> <device> [component]
      EVENT="$1"
      DEVICE="$2"
      COMPONENT="$3"
      TIMESTAMP="$(${date} '+%Y-%m-%d %H:%M:%S')"

      case "$EVENT" in
        Fail|FailSpare|DegradedArray|MoveSpare|SparesMissing)
          URGENCY="critical"
          ;;
        RebuildStarted|RebuildFinished|RebuildNN)
          URGENCY="normal"
          ;;
        TestMessage)
          URGENCY="low"
          ;;
        *)
          URGENCY="normal"
          ;;
      esac

      MSG="[$HOSTNAME] mdadm $EVENT on $DEVICE''${COMPONENT:+ (component: $COMPONENT)} at $TIMESTAMP"

      ${systemdCat} -t mdadm-notify -p \
        $([ "$URGENCY" = "critical" ] && echo "err" || echo "info") \
        echo "$MSG"

      for USER_NAME in $(${who} | ${awk} '{print $1}' | ${sort} -u); do
        USER_ID="$(${id} -u "$USER_NAME" 2>/dev/null)" || continue

        DISPLAY=":0" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" \
        XDG_RUNTIME_DIR="/run/user/$USER_ID" \
          ${sudo} -u "$USER_NAME" \
          ${notifySend} \
            --urgency="$URGENCY" \
            --icon="drive-harddisk" \
            --app-name="mdadm" \
            "RAID Alert: $EVENT" \
            "$MSG" 2>/dev/null || true
      done
    '';
in
{
  imports = [ ./disk.nix ];

  hardware = {
    enableAllFirmware = true;
    nvidia = {
      open = true; # driver open-source officiel NVIDIA
      modesetting.enable = true; # requis pour Wayland
      powerManagement.enable = true; # recommandé
    };
    bluetooth.settings.General.Experimental = true;
    saleae-logic.enable = true;
    openrazer = {
      enable = true;
      users = [ "ithinuel" ];
      batteryNotifier.enable = true;
    };
  };
  services = {
    hardware.openrgb.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
    gnome.games.enable = true;
  };

  boot = {
    # The rest of the RAID settings are populated by disko
    swraid.mdadmConf = ''
      PROGRAM ${mdadmNotify}
    '';

    loader = {
      # Lanzaboote currently replaces the systemd-boot module.
      # This setting is usually set to true in configuration.nix
      # generated at installation time. So we force it to false
      # for now.
      systemd-boot.enable = lib.mkForce false;
      efi = {
        # the primary boot partition
        efiSysMountPoint = "/boot0";
        # Allows the installer to modify EfiVariables (not sure why this’d be needed).
        canTouchEfiVariables = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";

      configurationLimit = 5;

      extraEfiSysMountPoints = [ "/boot1" ]; # Also install Lanzaboote on the secondary boot partition.

      # Auto generate the keys on first boot
      autoGenerateKeys.enable = true;

      # Auto enrole the key in the TPM & autoReboot to activate it
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };
    };

    # transparent ability to run cross build & run other aarch64’s binaries.
    binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      preferStaticEmulators = false;
    };
  };

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  sops.secrets.store-key = lib.mkDefault {
    sopsFile = pathRoot + "/secrets/nixbox.store-key.sops";
    format = "binary";
    mode = "0400";
  };
  nix.settings.secret-key-files = config.sops.secrets.store-key.path;
  nix.settings.trusted-public-keys = [
    "tleilax-1:TnLV90m+UmVwKCmz2rqH/ED78OrHFQZ79fnKGHQfGdw="
    "nixbox-1:+RhEM+GSeQmbFCaadAv6fQiuWzAF6f1FW4yuFhfHmYI="
  ];

  programs = {
    ghidra = {
      enable = true;
      gdb = true;
      package = pkgs.ghidra.withExtensions (p: with p; [
        gnudisassembler
      ]);
    };
    pulseview.enable = true;
    steam = {
      enable = true;
      # Translates the X11 Input events into uinput events. Need for using Steam Input in Wayland.
      extest.enable = true;
    };
    coolercontrol.enable = true;
  };

  environment.systemPackages = with pkgs; [
    (blender.override {
      config = {
        cudaSupport = true;
        rocmSupport = false;
      };
    })
  ];

  virtualisation.virtualbox.host.enable = true;

  security.pki.certificateFiles = [ (pathRoot + "/certs/ithinuel.local.crt") ];
  desktop.enable = true;
}
