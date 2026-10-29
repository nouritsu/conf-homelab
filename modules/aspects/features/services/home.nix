{
  den.aspects.services.homeassistant = let
    port = 8123;
  in {
    endpoint = {
      subdomain = "home";
      inherit port;
    };

    nixos = {
      virtualisation.oci-containers.containers.home-assistant = {
        image = "lscr.io/linuxserver/homeassistant:latest@sha256:ed6882bb24cc2e43857578c320b8e12b2b2fa768a6ef573ca8f768dcf1d48b22";
        # no ports: --net=host publishes nothing, podman discards them
        extraOptions = ["--net=host" "--cap-add=NET_ADMIN" "--cap-add=NET_RAW"];
        volumes = ["/data/homeassistant:/config" "/run/dbus:/run/dbus:ro" "/proc:/host/proc:ro"];
      };

      systemd.tmpfiles.rules = ["d /data/homeassistant 0775 1000 data -"];
    };
  };
}
