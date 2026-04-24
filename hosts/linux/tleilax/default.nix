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
  imports = [
    ./disk.nix
  ];

  sops.secrets.store-key = lib.mkDefault {
    sopsFile = pathRoot + "/secrets/nixbox.store-key.sops";
    format = "binary";
    mode = "0400";
  };
  nix.settings.secret-key-files = config.sops.secrets.store-key.path;
  nix.settings.trusted-public-keys = [ "nixbox-1:+RhEM+GSeQmbFCaadAv6fQiuWzAF6f1FW4yuFhfHmYI=" ];

  virtualisation.virtualbox.guest.enable = false;

  # The rest of the RAID settings are populated by disko
  boot.swraid.mdadmConf = ''
    PROGRAM ${mdadmNotify}
  '';

  # Bootloader with lanzaboote for Secure Boot + measured boot
  boot = {
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

    initrd = {
      # Required for measured boot
      systemd.enable = true;

      # Configure single LUKS encryption for the entire RAID array
      luks.devices."root" = {
        device = "/dev/md/root";
        keyFile = "/tmp/secret.key";
        allowDiscards = true;
      };
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";

      configurationLimit = 8; # Required when measured boot is enabled.
      extraEfiSysMountPoints = [ "/boot1" ]; # Also install Lanzaboote on the secondary boot partition.

      # Auto generate the keys on first boot
      autoGenerateKeys.enable = true;

      # Auto enrole the key in the TPM & autoReboot to activate it
      autoEnrollKeys = {
        enable = true;
        autoReboot = true;
      };

      # Enable measured boot (to auto unlock the LUKS volume)
      # Needs call to systemd-cryptenroll, make sure to enroll with a pin too for added security.
      measuredBoot = {
        enable = true;
        pcrs = [
          0 # SRTM, BIOS, Host Platform extensions, Embedded Option ROMs and PI Drivers
          4 # UEFI Boot Manager Code and Boot Attempts
          7 # Secure Boot Policy
        ];
        # Auto enroll the TPM
        autoCryptenroll = {
          enable = true;
          device = "/dev/disk/by-id/cryptroot"; # Confirm what’s the actual name of this device
        };
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  security.pki.certificateFiles = [ (pathRoot + "/certs/ithinuel.local.crt") ];
  desktop.enable = true;
}
