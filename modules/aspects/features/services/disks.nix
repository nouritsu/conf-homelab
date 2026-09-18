{den, ...}: {
  den.aspects.srv-scrutiny.nixos = {...}: let
    inherit (den.lib.homelab) endpoint;
    port = 8180;

    root = "/dev/nvme0n1";
    hdd-1tb = "/dev/sda";
    hdd-2tb = "/dev/sdb";
  in {
    imports = [
      (endpoint {
        subdomain = "disks";
        inherit port;
      })
    ];

    virtualisation.oci-containers.containers.scrutiny = {
      image = "ghcr.io/starosdev/scrutiny:latest-omnibus";
      ports = ["${toString port}:8080" "8187:8086"];
      extraOptions = ["--cap-add=SYS_ADMIN" "--cap-add=SYS_RAWIO"];
      devices = [hdd-1tb hdd-2tb root];
      volumes = [
        "/run/udev:/run/udev:ro"
        "/data/scrutiny/config:/opt/scrutiny/config"
        "/data/scrutiny/influxdb:/opt/scrutiny/influxdb"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /data/scrutiny 0755 root root -"
      "d /data/scrutiny/config 0755 root root -"
      "d /data/scrutiny/influxdb 0755 root root -"
    ];
  };
}
