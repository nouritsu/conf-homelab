{self, ...}: {
  flake.nixosModules = {
    caddy = {
      config,
      lib,
      ...
    }: {
      services.caddy.enable = true;
      networking.firewall.allowedTCPPorts = [80 443];

      security.pki.certificateFiles = [
        ../../assets/caddy.crt
      ];

      # two endpoints claiming one domain merge into a single vhost rather than
      # conflicting, so catch it here
      assertions =
        lib.mapAttrsToList (domain: vhost: {
          assertion = lib.count (lib.hasInfix "reverse_proxy") (lib.splitString "\n" vhost.extraConfig) <= 1;
          message = "caddy: ${domain} has more than one reverse_proxy - two endpoints claim this domain";
        })
        config.services.caddy.virtualHosts;
    };

    gluetun = {config, ...}: {
      imports = [self.nixosModules.gluetun-secrets];

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
        ports = ["8888:8888" "8388:8388" "59610:59610" "59610:59610/udp"];
      };

      systemd.timers.restart-container-gluetun.enable = false; # vpn
    };

    gluetun-secrets = {config, ...}: {
      sops.secrets."airvpn/wg-key" = {};
      sops.secrets."airvpn/wg-preshared-key" = {};
      sops.templates."gluetun.env" = {
        content = ''
          WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."airvpn/wg-key"}
          WIREGUARD_PRESHARED_KEY=${config.sops.placeholder."airvpn/wg-preshared-key"}
        '';
      };
    };

    rathole = {
      config,
      lib,
      ...
    }: {
      imports = [self.nixosModules.rathole-secrets];
      services.rathole = {
        enable = true;
        role = "client";
        credentialsFile = config.sops.templates."rathole-credentials.toml".path;
      };
      sops.templates."rathole-credentials.toml".content = lib.mkBefore ''
        [client]
        remote_addr = "${config.sops.placeholder."rathole/remote-addr"}"
      '';
    };

    rathole-secrets = {...}: {
      sops.secrets."rathole/token" = {};
      sops.secrets."rathole/remote-addr" = {};
    };

    postfix = {
      config,
      pkgs,
      ...
    }: {
      imports = [self.nixosModules.postfix-secrets];
      services.postfix = {
        enable = true;
        settings.main = {
          mydomain = "nouritsu.com";
          myorigin = "nouritsu.com";
          mydestination = [];
          mynetworks = ["127.0.0.0/8" "[::1]/128" "192.168.1.0/24"];
          relayhost = ["[smtp.hostinger.com]:465"];
          smtp_tls_security_level = "encrypt";
          smtp_tls_wrappermode = "yes";
          smtp_sasl_auth_enable = "yes";
          smtp_sasl_password_maps = "texthash:${config.sops.templates."mail-sasl-password".path}";
          smtp_sasl_security_options = "noanonymous";
          inet_interfaces = "loopback-only";
        };
      };
      environment.systemPackages = [pkgs.mailutils];
    };

    postfix-secrets = {config, ...}: {
      sops.secrets."mail/home-password" = {};
      sops.secrets."mail/home-mail" = {};
      sops.templates."mail-sasl-password" = {
        content = "[smtp.hostinger.com]:465 ${config.sops.placeholder."mail/home-mail"}:${config.sops.placeholder."mail/home-password"}";
      };
    };
  };
}
