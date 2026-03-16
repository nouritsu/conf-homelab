{
  flake.nixosModules.srv-bazarr = {config, ...}: let
    endpoint = config.my.endpoints.bazarr;
  in {
    my.endpoints.bazarr = {
      enable = true;
      tlsInternal = true;
      port = 8088;
      subdomain = "subs";
    };

    my.containers.bazarr = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:6767"];
      vols = ["/data/bazarr:/config" "/media/media:/media"];
    };

    systemd.tmpfiles.rules = ["d /data/bazarr 0775 1000 data -"];
  };
}
