{den, ...}: let
  inherit (den.lib.homelab) fqdn lan-cidr;
in {
  den.aspects.services.tailscale.nixos = {config, ...}: {
    sops.secrets."tailscale/authkey" = {};

    sops.templates."tailscale.env" = {
      content = ''
        TS_AUTHKEY=${config.sops.placeholder."tailscale/authkey"}
      '';
    };

    virtualisation.oci-containers.containers.tailscale = {
      image = "ghcr.io/tailscale/tailscale:latest@sha256:b11583ad2e93e4671128538c88cf11f460444a5d7e449311dd1933a400ab849d";

      environment = {
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_EXTRA_ARGS = "--reset --login-server=https://${fqdn "vpn"} --advertise-routes=${lan-cidr} --accept-dns=false";
      };

      environmentFiles = [config.sops.templates."tailscale.env".path];

      volumes = [
        "/data/tailscale:/var/lib/tailscale"
        "/dev/net/tun:/dev/net/tun"
      ];

      extraOptions = [
        "--network=host"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
        "--privileged"
      ];
    };

    systemd.timers.restart-container-tailscale.enable = false; # vpn

    systemd.tmpfiles.rules = [
      "d /data/tailscale 0775 1000 data -"
    ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.firewall.checkReversePath = "loose";
  };
}
