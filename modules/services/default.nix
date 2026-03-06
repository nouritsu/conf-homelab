{
  imports = [
    # ./container.nix
    ./books # readarr (bookshelf fork)
    ./cook # cook-cli
    ./disks # scrutiny
    ./docs # paperless ngx
    ./home # glance
    ./indexes # prowlarr
    ./mail # roundcube
    ./media # jellyseerr
    ./monitor # uptime kuma
    ./movies # radarr
    ./pihole
    ./player # jellyfin
    ./shows # sonarr
    ./share # enclosed
    ./sign # documenso
    ./speed # myspeed
    ./photos # immich
    ./sync # syncthing
    ./download # aria2
    ./torrent # qbittorrent
    ./usenet # sabnzbd
    ./vault # vaultwarden
    ./vpn

    ./caddy.nix
    ./rathole.nix
    ./gluetun.nix
  ];
}
