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
        image = "ghcr.io/pennydreadful/bookshelf:hardcover@sha256:388eecc94362580eae31ee0a454be6af516f8a311f8432a521c202fb475f4359";
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
