{
  flake.nixosModules.srv-sonarr = {config, ...}: let
    endpoint = config.my.endpoints.sonarr;
  in {
    my.endpoints.sonarr = {
      port = 8086;
      subdomain = "shows";
    };
    my.containers.sonarr = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:8989"];
      vols = ["/data/sonarr:/config" "/media/download:/data" "/media/media:/media"];
    };
    systemd.tmpfiles.rules = [
      "d /data/sonarr 0775 1000 data -"
      "d /media/media/shows 2775 1000 data -"
    ];
  };
}
