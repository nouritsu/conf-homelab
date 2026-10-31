{den, ...}: let
  port = 8086;
in {
  den.aspects.services.sonarr = {
    endpoint = {
      subdomain = "shows";
      inherit port;
    };
    gluetun-ports = ["${toString port}:8989"];

    nixos = {
      imports = [(den.lib.homelab.via-gluetun "sonarr")];

      virtualisation.oci-containers.containers.sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest@sha256:386c962ee6e260e3a5656b25df2ed056bcc9b6410e197d075f9547fd14c23bca";
        volumes = ["/data/sonarr:/config" "/media/download:/data" "/media/media:/media"];
      };

      systemd.tmpfiles.rules = [
        "d /data/sonarr 0775 1000 data -"
        "d /media/media/shows 2775 1000 data -"
      ];
    };
  };
}
