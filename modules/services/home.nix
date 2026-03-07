{
  flake.nixosModules.srv-homeassistant = {config, ...}: let
    endpoint = config.my.endpoints.home-assistant;
  in {
    my.endpoints.home-assistant = {
      enable = true;
      tlsInternal = true;
      port = 8123;
      subdomain = "home";
    };

    my.containers.home-assistant = {
      enable = true;
      image = {
        name = "homeassistant";
        provider = "lscr";
      };
      vols = ["/data/homeassistant:/config" "/run/dbus:/run/dbus:ro" "/proc:/host/proc:ro"];
      ports = ["${toString endpoint.port}:8123"];
      extra-options = ["--net=host" "--cap-add=NET_ADMIN" "--cap-add=NET_RAW"];
    };
    systemd.tmpfiles.rules = ["d /data/homeassistant 0775 1000 data -"];
  };
}
