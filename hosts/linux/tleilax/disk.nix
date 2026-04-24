{ lib, ... }:
{
  disko.devices.disk = lib.genAttrs' [
    { name = "kingston"; boot = "0"; device = "ata-KINGSTON_SUV400S37120G_50026B777303A3D1"; }
    { name = "ocz"; boot = "1"; device = "ata-OCZ-VERTEX3_OCZ-3J60Z5X04RAUI944"; }
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
              name = "raid1";
            };
          };
        };
      };
    });
  disko.devices.mdadm = {
    raid1 = {
      type = "mdadm";
      level = 1;
      content = {
        type = "luks";
        name = "crypted";
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
