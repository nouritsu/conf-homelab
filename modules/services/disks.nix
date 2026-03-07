{
  flake.nixosModules.srv-scrutiny = {config, ...}: let
    endpoint = config.my.endpoints.scrutiny;
    root = "/dev/nvme0n1";
    hdd-1tb = "/dev/sda";
    hdd-2tb = "/dev/sdb";
  in {
    my.endpoints.scrutiny = {
      enable = true;
      port = 8180;
      subdomain = "disks";
    };
    my.containers.scrutiny = {
      enable = true;
      image = {
        provider = "ghcr";
        owner = "starosdev";
        tag = "latest-omnibus";
      };
      ports = ["${toString endpoint.port}:8080" "8187:8086"];
      vols = [
        "/run/udev:/run/udev:ro"
        "/data/scrutiny/config:/opt/scrutiny/config"
        "/data/scrutiny/influxdb:/opt/scrutiny/influxdb"
      ];
      extra-options = ["--cap-add=SYS_ADMIN" "--cap-add=SYS_RAWIO"];
      devices = [hdd-1tb hdd-2tb root];
    };
    systemd.tmpfiles.rules = [
      "d /data/scrutiny 0755 root root -"
      "d /data/scrutiny/config 0755 root root -"
      "d /data/scrutiny/influxdb 0755 root root -"
    ];
  };
}
