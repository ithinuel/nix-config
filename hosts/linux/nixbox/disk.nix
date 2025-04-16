{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              end = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              end = "-5G";
              content = {
                type = "btrfs";
                mountpoint = "/";
                extraArgs = [ "-f" ]; # Override existing partition
              };
            };
            swap = {
              size = "100%";
              content = {
                type = "swap";
                resumeDevice = true; # resume from hibernation from this device
              };
            };
          };
        };
      };
    };
  };
}
