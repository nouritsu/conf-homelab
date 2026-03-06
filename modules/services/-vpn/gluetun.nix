{config, ...}: {
  sops.secrets."airvpn-wg-key" = {};
  sops.secrets."airvpn-wg-preshared-key" = {};

  sops.templates."gluetun.env" = {
    content = ''
      WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."airvpn-wg-key"}
      WIREGUARD_PRESHARED_KEY=${config.sops.placeholder."airvpn-wg-preshared-key"}
    '';
  };

  my.containers.gluetun = {
    enable = true;

    image = {
      owner = "qmcgaw";
      provider = "official";
    };

    env = {
      VPN_SERVICE_PROVIDER = "airvpn";
      VPN_TYPE = "wireguard";
      WIREGUARD_ADDRESSES = "10.168.189.140/32";
      SERVER_COUNTRIES = "Switzerland";
      FIREWALL_VPN_INPUT_PORTS = "59610";
    };

    envFile = [
      config.sops.templates."gluetun.env".path
    ];

    extra-options = [
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
      "--device=/dev/net/tun:/dev/net/tun"
    ];

    ports = [
      "8888:8888"
      "8388:8388"
      "59610:59610"
      "59610:59610/udp"
    ];
  };
}
