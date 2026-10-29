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
        image = "lscr.io/linuxserver/radarr:latest@sha256:084b3b2ab1d0ef930660727259546a241f2bdf67c9ed085d54bf1486a6887c9b";
        volumes = ["/data/radarr:/config" "/media/download:/data" "/media/media:/media"];
      };

      systemd.tmpfiles.rules = [
        "d /data/radarr 0775 1000 data -"
        "d /media/media/movies 2775 1000 data -"
      ];
    };
  };
}
