{self, ...}: {
  flake.nixosModules = {
    srv-wg-easy = {config, ...}: let
      wg-port = 51820;
      data-dir = "/data/wg-easy";
      endpoint = config.my.endpoints.wg-easy;
    in {
      imports = [self.nixosModules.wg-easy-secrets];
      my.endpoints.wg-easy = {
        enable = true;
        tlsInternal = true;
        port = 51821;
        subdomain = "vpn";
      };
      my.containers.wg-easy = {
        enable = true;
        restart.enable = false; # vpn
        image = {
          tag = "15";
          provider = "ghcr";
        };
        env = {
          INIT_ENABLED = "true";
          INIT_USERNAME = "admin";
          INIT_DNS = "192.168.178.128,1.1.1.1";
          WG_POST_UP = "";
          WG_POST_DOWN = "";
        };
        envFile = [config.sops.templates."wg-easy.env".path];
        vols = [
          "${data-dir}:/etc/wireguard"
          "/run/booted-system/kernel-modules/lib/modules:/lib/modules:ro"
        ];
        extra-options = ["--privileged" "--network=host"];
        ports = [
          "${toString wg-port}:51820/udp"
          "${toString endpoint.port}:51821/tcp"
        ];
      };
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.src_valid_mark" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;
      };
      networking.nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = "end0";
        internalInterfaces = ["wg0"];
      };
      networking.firewall = {
        allowedUDPPorts = [wg-port];
        trustedInterfaces = ["wg0"];
      };
      systemd.tmpfiles.rules = ["d ${data-dir} 0700 root root -"];
    };

    wg-easy-secrets = {config, ...}: {
      sops.secrets."wg-server-public-ip" = {};
      sops.secrets."wg-easy-password" = {};
      sops.templates."wg-easy.env" = {
        content = ''
          INIT_HOST=${config.sops.placeholder."wg-server-public-ip"}
          INIT_PASSWORD=${config.sops.placeholder."wg-easy-password"}
        '';
      };
    };
  };
}
