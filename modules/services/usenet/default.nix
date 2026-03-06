{config, ...}: let
  endpoint = config.my.endpoints.usenet;
in {
  my.endpoints.usenet.port = 8083;

  my.containers.sabnzbd = {
    enable = true;
    vpn = true;
    image.provider = "lscr";
    ports = ["${toString endpoint.port}:8080"];

    theme = {
      enable = true;
      provider = "ghcr";
      is-community-theme = true;
      theme-name = "catppuccin-mocha";
    };

    vols = ["/data/sabnzbd:/config" "/media/download:/data"];
  };

  systemd.tmpfiles.rules = [
    "d /data/sabnzbd 0775 1000 data -"
    "d /media/download/usenet 2775 1000 data -"
    "d /media/download/usenet/nzbs 2775 1000 data -"
    "d /media/download/usenet/incomplete 2775 1000 data -"
    "d /media/download/usenet/complete 2775 1000 data -"
  ];

  # add hosts to whitelist
  systemd.services.podman-sabnzbd.preStart = ''
    mkdir -p /data/sabnzbd

    config_file="/data/sabnzbd/sabnzbd.ini"
    whitelist_hosts="${config.my.endpoints.usenet.domain}, localhost, 127.0.0.1"

    if [ -f "$config_file" ]; then
      if grep -q "^host_whitelist" "$config_file"; then
        sed -i "s|^host_whitelist.*|host_whitelist = $whitelist_hosts|" "$config_file"
      else
        if grep -q "^\[misc\]" "$config_file"; then
          sed -i "/^\[misc\]/a host_whitelist = $whitelist_hosts" "$config_file"
        fi
      fi
    fi
  '';
}
