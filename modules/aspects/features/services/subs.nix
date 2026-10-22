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
        image = "lscr.io/linuxserver/bazarr:latest@sha256:946dc8c5bb5331418eac60050cf40a63cb8f66ac039841dda493870e3559799c";
        volumes = ["/data/bazarr:/config" "/media/media:/media"];
      };

      systemd.tmpfiles.rules = ["d /data/bazarr 0775 1000 data -"];
    };
  };
}
