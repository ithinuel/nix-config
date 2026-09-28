{ lib, ... }:
{
  disko.devices.disk = lib.genAttrs' [
    { name = "nvme0"; boot = "0"; device = "nvme-KINGSTON_OM8TAP42048K1-A00_50026B73845011D3"; }
    { name = "nvme1"; boot = "1"; device = "nvme-WD_Green_SN3000_2TB_260449802917"; }
  ]
    ({ name, boot, device }: lib.nameValuePair "${name}" {
      type = "disk";
      device = "/dev/disk/by-id/${device}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "500M";
            name = "ESP";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot${boot}";
              mountOptions = [ "umask=0077" ];
            };
          };
          mdadm = {
            size = "100%";
            content = {
              type = "mdraid";
              name = "raid-root";
            };
          };
        };
      };
    });
  disko.devices.mdadm = {
    raid-root = {
      type = "mdadm";
      level = 1;
      extraArgs = [ "--bitmap=internal" ];
      content = {
        type = "luks";
        name = "luks-root";
        settings.allowDiscards = true;
        content = {
          type = "btrfs";
          extraArgs = [ "-L" "nixos" "-f" ];
          subvolumes =
            let
              mountOptions = [ "compress=zstd:1" "noatime" ];
              mkVolumes = name: lib.nameValuePair "@${name}" { mountpoint = "/${name}"; inherit mountOptions; };
            in
            lib.genAttrs' [ "" "home" "nix" ] mkVolumes;
        };
      };
    };
  };
}
