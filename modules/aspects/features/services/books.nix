{den, ...}: let
  port = 8787;
in {
  den.aspects.services.bookshelf = {
    endpoint = {
      subdomain = "books";
      inherit port;
    };
    gluetun-ports = ["${toString port}:8787"];

    nixos = {config, ...}: {
      imports = [(den.lib.homelab.via-gluetun "bookshelf")];

      virtualisation.oci-containers.containers.bookshelf = {
        image = "ghcr.io/pennydreadful/bookshelf:hardcover@sha256:67498dd5ece516867d72ee642abd6c1a66b36a135c8f7da0127109564372beb1";
        extraOptions = ["--user=1000:${toString config.users.groups.data.gid}"];
        volumes = ["/data/bookshelf:/config" "/media/download:/data" "/media/media:/media"];
      };

      systemd.tmpfiles.rules = [
        "d /data/bookshelf 0775 1000 data -"
        "d /media/media/books 2775 1000 data -"
      ];
    };
  };
}
