{
  # consumes the `gluetun-ports` quirk: every port a service behind this vpn
  # container needs published
  den.aspects.gluetun.nixos = {
    gluetun-ports,
    config,
    lib,
    ...
  }: {
    sops.secrets."airvpn/wg-key" = {};
    sops.secrets."airvpn/wg-preshared-key" = {};
    sops.templates."gluetun.env" = {
      content = ''
        WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."airvpn/wg-key"}
        WIREGUARD_PRESHARED_KEY=${config.sops.placeholder."airvpn/wg-preshared-key"}
      '';
    };

    virtualisation.oci-containers.containers.gluetun = {
      image = "qmcgaw/gluetun:latest";
      environment = {
        VPN_SERVICE_PROVIDER = "airvpn";
        VPN_TYPE = "wireguard";
        WIREGUARD_ADDRESSES = "10.168.189.140/32";
        SERVER_COUNTRIES = "Switzerland";
        FIREWALL_VPN_INPUT_PORTS = "59610";
      };
      environmentFiles = [config.sops.templates."gluetun.env".path];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
        "--device=/dev/net/tun:/dev/net/tun"
      ];
      ports =
        ["8888:8888" "8388:8388" "59610:59610" "59610:59610/udp"]
        ++ lib.sort (a: b: a < b) gluetun-ports;
    };

    systemd.timers.restart-container-gluetun.enable = false; # vpn
  };
}
