{
  flake.nixosModules = {
    srv-qbittorrent = {config, ...}: let
      endpoint = config.my.endpoints.torrent;
    in {
      my.endpoints.torrent = {
        enable = true;
        tlsInternal = true;
        port = 8082;
        subdomain = "torrent";
      };

      my.containers.qbittorrent = {
        enable = true;
        vpn = true;
        image.provider = "lscr";
        ports = ["${toString endpoint.port}:8081"];

        env = {
          WEBUI_PORT = "8081";
          TORRENTING_PORT = "59610";
        };

        theme = {
          enable = true;
          provider = "ghcr";
          name = "vuetorrent";
          is-community-theme = true;
          theme-name = "catppuccin-mocha";
        };

        vols = ["/data/qbittorrent:/config" "/media/download:/data"];
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

    srv-mousehole = {config, ...}: let
      endpoint = config.my.endpoints.mousehole;
    in {
      my.endpoints.mousehole = {
        enable = true;
        tlsInternal = true;
        port = 5010;
        subdomain = "mam";
      };

      my.containers.mousehole = {
        enable = true;
        vpn = true;
        image = {
          provider = "official";
          owner = "tmmrtn";
          name = "mousehole";
        };
        ports = ["${toString endpoint.port}:5010"];
        vols = ["/data/mousehole:/srv/mousehole"];
      };

      systemd.tmpfiles.rules = [
        "d /data/mousehole 0775 1000 data -"
      ];
    };
  };
}
