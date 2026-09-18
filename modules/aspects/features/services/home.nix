{den, ...}: {
  den.aspects.srv-homeassistant.nixos = {...}: let
    inherit (den.lib.homelab) endpoint;
    port = 8123;
  in {
    imports = [
      (endpoint {
        subdomain = "home";
        inherit port;
      })
    ];

    virtualisation.oci-containers.containers.home-assistant = {
      image = "lscr.io/linuxserver/homeassistant:latest";
      ports = ["${toString port}:8123"];
      extraOptions = ["--net=host" "--cap-add=NET_ADMIN" "--cap-add=NET_RAW"];
      volumes = ["/data/homeassistant:/config" "/run/dbus:/run/dbus:ro" "/proc:/host/proc:ro"];
    };

    systemd.tmpfiles.rules = ["d /data/homeassistant 0775 1000 data -"];
  };
}
