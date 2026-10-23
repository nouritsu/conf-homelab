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
          image = "lscr.io/linuxserver/qbittorrent:latest@sha256:e887804fa9de4c60f5f0fb1f3a7e4febe40a8f69fe736f70c4e8589b1f868dab";

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

      nixos = {
        imports = [(den.lib.homelab.via-gluetun "mousehole")];

        virtualisation.oci-containers.containers.mousehole = {
          image = "tmmrtn/mousehole:latest@sha256:2fc02b12362581e60bfd6adba788bda9eda93f8f31ed089581eeabcee4518b0d";
          volumes = ["/data/mousehole:/srv/mousehole"];
        };

        systemd.tmpfiles.rules = ["d /data/mousehole 0775 1000 data -"];
      };
    };
  };
}
