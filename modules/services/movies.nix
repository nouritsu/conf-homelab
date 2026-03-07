{
  flake.nixosModules.srv-radarr = {config, ...}: let
    endpoint = config.my.endpoints.radarr;
  in {
    my.endpoints.radarr = {
      enable = true;
      port = 8085;
      subdomain = "movies";
    };
    my.containers.radarr = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:7878"];
      vols = ["/data/radarr:/config" "/media/download:/data" "/media/media:/media"];
    };
    systemd.tmpfiles.rules = [
      "d /data/radarr 0775 1000 data -"
      "d /media/media/movies 2775 1000 data -"
    ];
  };
}
