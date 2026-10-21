{den, ...}: let
  port = 8085;
in {
  den.aspects.services.radarr = {
    endpoint = {
      subdomain = "movies";
      inherit port;
    };
    gluetun-ports = ["${toString port}:7878"];

    nixos = {
      imports = [(den.lib.homelab.via-gluetun "radarr")];

      virtualisation.oci-containers.containers.radarr = {
        image = "lscr.io/linuxserver/radarr:latest@sha256:270f25698624b57b86ca119cc95399d7ff15be8297095b4e1223fd5b549b732c";
        volumes = ["/data/radarr:/config" "/media/download:/data" "/media/media:/media"];
      };

      systemd.tmpfiles.rules = [
        "d /data/radarr 0775 1000 data -"
        "d /media/media/movies 2775 1000 data -"
      ];
    };
  };
}
