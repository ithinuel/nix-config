{ lib, pkgs }:
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
''
