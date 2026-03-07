{
  flake.nixosModules.srv-bookshelf = {config, ...}: let
    endpoint = config.my.endpoints.bookshelf;
  in {
    my.endpoints.bookshelf = {
      port = 8787;
      subdomain = "books";
    };
    my.containers.bookshelf = {
      enable = true;
      vpn = true;
      ports = ["${toString endpoint.port}:8787"];
      image = {
        owner = "pennydreadful";
        name = "bookshelf";
        tag = "hardcover";
        provider = "ghcr";
      };
      extra-options = ["--user=1000:${toString config.users.groups.data.gid}"];
      vols = ["/data/bookshelf:/config" "/media/download:/data" "/media/media:/media"];
    };
    systemd.tmpfiles.rules = [
      "d /data/bookshelf 0775 1000 data -"
      "d /media/media/books 2775 1000 data -"
    ];
  };
}
