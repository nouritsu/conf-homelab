{self, ...}: {
  flake.nixosModules = {
    srv-qbittorrent = {...}: let
      inherit (self.lib) endpoint via-gluetun;
      port = 8082;
    in {
      imports = [
        (endpoint {
          subdomain = "torrent";
          inherit port;
        })
        (via-gluetun "qbittorrent" ["${toString port}:8081"])
      ];

      virtualisation.oci-containers.containers.qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";

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

    srv-mousehole = {...}: let
      inherit (self.lib) endpoint via-gluetun;
      port = 5010;
    in {
      imports = [
        (endpoint {
          subdomain = "mam";
          inherit port;
        })
        (via-gluetun "mousehole" ["${toString port}:5010"])
      ];

      virtualisation.oci-containers.containers.mousehole = {
        image = "tmmrtn/mousehole:latest";
        volumes = ["/data/mousehole:/srv/mousehole"];
      };

      systemd.tmpfiles.rules = [
        "d /data/mousehole 0775 1000 data -"
      ];
    };
  };
}
