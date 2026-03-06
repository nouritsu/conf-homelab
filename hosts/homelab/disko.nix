{inputs, ...}: {
  flake.nixosModules.homelab-disko = {
    imports = [
      inputs.disko.nixosModules.disko
    ];

    systemd.tmpfiles.rules = [
      "d /data 2775 1000 data -"
    ];

    disko.devices = {
      disk.nvme = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            firmware = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/firmware";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime"];
                subvolumes = {
                  "@data" = {
                    mountpoint = "/data";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
