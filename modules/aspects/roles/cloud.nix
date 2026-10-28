# base, on a rented x86 vm: a qemu guest on one btrfs disk, on the provider's dhcp.
{den, ...}: {
  den.aspects.cloud = {
    includes = with den.aspects; [
      base
      filesystem.btrfs
    ];

    nixos = {modulesPath, ...}: {
      imports = [(modulesPath + "/profiles/qemu-guest.nix")];
      boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
      boot.initrd.kernelModules = ["nvme"];

      boot.tmp.cleanOnBoot = true;
      zramSwap.enable = true;
      services.logrotate.checkConfig = false;

      users.groups.data.gid = 993;
      systemd.tmpfiles.rules = ["z /data 2775 root data -"];
    };
  };
}
