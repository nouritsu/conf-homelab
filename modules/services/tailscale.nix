{self, ...}: {
  flake.nixosModules = {
    srv-tailscale = {config, ...}: {
      imports = [
        self.nixosModules.tailscale-secrets
      ];

      my.containers.tailscale = {
        enable = true;
        restart.enable = false; # vpn

        image = {
          provider = "ghcr";
          owner = "tailscale";
          name = "tailscale";
          tag = "latest";
        };

        env = {
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_EXTRA_ARGS = "--login-server=https://vpn.nouritsu.com --advertise-exit-node --advertise-routes=192.168.178.0/24 --accept-dns=false";
        };

        envFile = [config.sops.templates."tailscale.env".path];

        vols = [
          "/data/tailscale:/var/lib/tailscale"
          "/dev/net/tun:/dev/net/tun"
        ];

        extra-options = [
          "--network=host"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
          "--privileged"
        ];
      };

      systemd.tmpfiles.rules = [
        "d /data/tailscale 0775 1000 data -"
      ];

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      networking.firewall.checkReversePath = "loose";
    };

    tailscale-secrets = {config, ...}: {
      sops.secrets."tailscale/authkey" = {};

      sops.templates."tailscale.env" = {
        content = ''
          TS_AUTHKEY=${config.sops.placeholder."tailscale/authkey"}
        '';
      };
    };
  };
}
