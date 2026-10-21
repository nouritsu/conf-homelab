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
      image = "ghcr.io/tailscale/tailscale:latest@sha256:95e528798bebe75f39b10e74e7051cf51188ee615934f232ba7ad06a3390ffa1";

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
