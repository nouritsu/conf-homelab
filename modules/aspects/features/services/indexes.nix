{den, ...}: let
  port = 8084;
in {
  den.aspects.services.prowlarr = {
    endpoint = {
      subdomain = "indexes";
      inherit port;
    };
    gluetun-ports = ["${toString port}:9696"];

    nixos = {
      imports = [(den.lib.homelab.via-gluetun "prowlarr")];

      virtualisation.oci-containers.containers.prowlarr = {
        image = "lscr.io/linuxserver/prowlarr:latest@sha256:d3e9307b320b6772749a2cf8fc2712e9e824c4930b034680ad4d08a9e2f25884";
        volumes = ["/data/prowlarr:/config"];
      };

      systemd.tmpfiles.rules = ["d /data/prowlarr 0775 1000 data -"];
    };
  };
}
