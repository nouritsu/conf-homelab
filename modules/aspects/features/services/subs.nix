{den, ...}: let
  port = 8088;
in {
  den.aspects.services.bazarr = {
    endpoint = {
      subdomain = "subs";
      inherit port;
    };
    gluetun-ports = ["${toString port}:6767"];

    nixos = {
      imports = [(den.lib.homelab.via-gluetun "bazarr")];

      virtualisation.oci-containers.containers.bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest@sha256:d40ee61030a9afafddfdd58d160281b865bfcad7cb66e920116fd6fd40668cbb";
        volumes = ["/data/bazarr:/config" "/media/media:/media"];
      };

      systemd.tmpfiles.rules = ["d /data/bazarr 0775 1000 data -"];
    };
  };
}
