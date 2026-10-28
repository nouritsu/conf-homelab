{den, ...}: let
  qbit-port = 8082;
  mam-port = 5010;
in {
  den.aspects.services = {
    qbittorrent = {
      endpoint = {
        subdomain = "torrent";
        port = qbit-port;
      };
      gluetun-ports = ["${toString qbit-port}:8081"];

      nixos = {
        imports = [(den.lib.homelab.via-gluetun "qbittorrent")];

        virtualisation.oci-containers.containers.qbittorrent = {
          image = "lscr.io/linuxserver/qbittorrent:5.2.4@sha256:1ea873647c43d566f251a7122aee330b184509c57ee3257ed19f62dac0f8f24b";

          environment = {
            WEBUI_PORT = "8081";
            TORRENTING_PORT = "59610";

            DOCKER_MODS = "ghcr.io/themepark-dev/theme.park:vuetorrent";
            TP_THEME = "catppuccin-mocha";
            TP_COMMUNITY_THEME = "true";
          };

          volumes = ["/data/qbittorrent:/config" "/media/download:/data"];
        };

        systemd.tmpfiles.rules = [
          "d /data/qbittorrent 0775 1000 data -"
          "d /media/download/torrent 2775 1000 data -"
          "d /media/download/torrent/torrents 2775 1000 data -"
          "d /media/download/torrent/incomplete 2775 1000 data -"
          "d /media/download/torrent/complete 2775 1000 data -"
          "d /media/download/torrent/complete/movies 2775 1000 data -"
          "d /media/download/torrent/complete/shows 2775 1000 data -"
          "d /media/download/torrent/complete/books 2775 1000 data -"
        ];
      };
    };

    mousehole = {
      endpoint = {
        subdomain = "mam";
        port = mam-port;
      };
      gluetun-ports = ["${toString mam-port}:5010"];

      nixos = {config, ...}: let
        domain = den.lib.homelab.fqdn "mam";
      in {
        imports = [(den.lib.homelab.via-gluetun "mousehole")];

        sops.secrets."mousehole/password" = {};
        sops.templates."mousehole.env" = {
          content = ''
            MOUSEHOLE_AUTH_PASSWORD=${config.sops.placeholder."mousehole/password"}
          '';
        };

        virtualisation.oci-containers.containers.mousehole = {
          image = "tmmrtn/mousehole:latest@sha256:2fc02b12362581e60bfd6adba788bda9eda93f8f31ed089581eeabcee4518b0d";

          # only ever reached through caddy's https vhost
          environment = {
            MOUSEHOLE_ALLOWED_HOSTS = domain;
            MOUSEHOLE_ALLOWED_ORIGINS = "https://${domain}";
            MOUSEHOLE_HTTPS_ONLY_COOKIES = "true";
          };

          environmentFiles = [config.sops.templates."mousehole.env".path];
          volumes = ["/data/mousehole:/var/lib/mousehole"];
        };

        systemd.tmpfiles.rules = ["d /data/mousehole 0775 1000 data -"];
      };
    };
  };
}
