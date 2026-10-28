{inputs, ...}: {
  den.aspects.nenya.disko.nixos = {
    imports = [
      inputs.disko.nixosModules.disko
    ];

    disko.devices.disk.main = {
      type = "disk";
      # verify with lsblk from the rescue system before installing
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # BIOS boot
          };
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@data" = {
                  mountpoint = "/data";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@swap" = {
                  mountpoint = "/swap";
                  mountOptions = ["noatime"];
                  swap.swapfile.size = "16G";
                };
              };
            };
          };
        };
      };
    };
  };
}
