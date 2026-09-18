{self, ...}: {
  flake.nixosModules.srv-bookshelf = {config, ...}: let
    inherit (self.lib) endpoint via-gluetun;
    port = 8787;
  in {
    imports = [
      (endpoint {
        subdomain = "books";
        inherit port;
      })
      (via-gluetun "bookshelf" ["${toString port}:8787"])
    ];

    virtualisation.oci-containers.containers.bookshelf = {
      image = "ghcr.io/pennydreadful/bookshelf:hardcover";
      extraOptions = ["--user=1000:${toString config.users.groups.data.gid}"];
      volumes = ["/data/bookshelf:/config" "/media/download:/data" "/media/media:/media"];
    };

    systemd.tmpfiles.rules = [
      "d /data/bookshelf 0775 1000 data -"
      "d /media/media/books 2775 1000 data -"
    ];
  };
}
