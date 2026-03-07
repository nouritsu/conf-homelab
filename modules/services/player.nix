{
  flake.nixosModules.srv-jellyfin = {config, ...}: let
    endpoint = config.my.endpoints.jellyfin;
  in {
    my.endpoints.jellyfin = {
      port = 8096;
      subdomain = "player";
    };
    my.containers.jellyfin = {
      enable = true;
      ports = ["${toString endpoint.port}:8096"];
      dri-passthrough = true;
      image = {
        name = "jellyfin";
        provider = "lscr";
      };
      vols = ["/data/jellyfin:/config" "/media/media:/media:ro"];
    };
    systemd.tmpfiles.rules = ["d /data/jellyfin 0775 1000 data -"];
  };
}
