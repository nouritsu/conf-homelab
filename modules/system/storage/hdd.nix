{pkgs, ...}: let
  hdd-opts = [
    "defaults"
    "nofail"
    "x-systemd.device-timeout=10s"
  ];
in {
  config = {
    environment.systemPackages = [pkgs.mergerfs];

    users.groups.data.gid = 993;

    fileSystems."/mnt/hdd-1tb" = {
      device = "/dev/disk/by-label/hdd-1tb";
      fsType = "xfs";
      options = hdd-opts;
    };

    fileSystems."/mnt/hdd-2tb" = {
      device = "/dev/disk/by-label/hdd-2tb";
      fsType = "xfs";
      options = hdd-opts;
    };

    fileSystems."/media" = {
      device = "/mnt/hdd-1tb:/mnt/hdd-2tb";
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "nonempty"
        "allow_other"
        "use_ino"
        "category.create=mfs"
        "moveonenospc=true"
        "dropcacheonclose=true"
        "fsname=mergerfs"
        "nofail"
        "x-systemd.requires=mnt-hdd\\x2d1tb.mount"
        "x-systemd.requires=mnt-hdd\\x2d2tb.mount"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /mnt/hdd-1tb 0775 1000 data -"
      "d /mnt/hdd-2tb 0775 1000 data -"
      "z /mnt/hdd-1tb 0775 1000 data -"
      "z /mnt/hdd-2tb 0775 1000 data -"
      "d /media 0775 1000 data -"
      "d /media/media 2775 1000 data -"
      "d /media/download 2775 1000 data -"
    ];
  };
}
