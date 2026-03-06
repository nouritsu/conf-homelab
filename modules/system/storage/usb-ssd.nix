{config, ...}: let
  user = config.my.user.alias;
  home = "/home/${user}";
  ssd-uuid = "79FA-77C0";
  ssd-mount = "${home}/usb-ssd";
in {
  config = {
    boot.supportedFilesystems = ["exfat"];

    fileSystems."${ssd-mount}" = {
      device = "/dev/disk/by-uuid/${ssd-uuid}";
      fsType = "exfat";
      options = [
        "defaults"
        "nofail"
        "x-systemd.device-timeout=10s"
        "uid=1000"
        "gid=1000"
        "dmask=022" # directories: 755
        "fmask=133" # files: 644
      ];
    };
  };
}
