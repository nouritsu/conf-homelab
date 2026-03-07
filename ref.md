
# Migration: modules/services/ to dendretic modules/srv/

## Context

Services in `modules/services/` are plain NixOS modules imported via a chain (`modules/default.nix` -> `services/default.nix` -> each service). The host loads them all with `++ [../../modules]`. We're migrating to the dendretic pattern already used by `modules/system/`, `modules/applications/`, etc., where each file exports `flake.nixosModules.*` entries discovered by `import-tree`.

## Rules

- Every NixOS module uses `module-name = {arg1, arg2, ...}: { body };` syntax (always include `...`)
- Files named by endpoint (subdomain). Modules named `srv-{app}`
- Secrets module: `{app}-secrets`, DB module: `{app}-db`, DB secrets: `{app}-db-secrets`
- `srv-{app}` imports its secrets/db via `self.nixosModules.{name}`
- `{app}-db` imports its own `{app}-db-secrets`
- Infrastructure services (no endpoint) go in `srv/services.nix`
- Shared secrets stay with original owner; consumers reference the sops placeholder directly

## Files to Modify

- `flake.nix` - add `(import-tree ./modules/srv)`
- `hosts/homelab/homelab.nix` - replace `++ [../../modules]` with explicit module list
- `modules/default.nix` - delete after migration
- `modules/services/` - delete entire directory after migration

## New Files (all under modules/srv/)

### srv/services.nix - Infrastructure

Contains: `caddy`, `gluetun` + `gluetun-secrets`, `rathole` + `rathole-secrets`, `postfix` + `postfix-secrets`

```nix
{self, ...}: {
  flake.nixosModules = {
    caddy = {...}: {
      services.caddy.enable = true;
      networking.firewall.allowedTCPPorts = [80 443];
    };

    gluetun = {config, ...}: {
      imports = [self.nixosModules.gluetun-secrets];
      my.containers.gluetun = {
        enable = true;
        image = { owner = "qmcgaw"; provider = "official"; };
        env = {
          VPN_SERVICE_PROVIDER = "airvpn";
          VPN_TYPE = "wireguard";
          WIREGUARD_ADDRESSES = "10.168.189.140/32";
          SERVER_COUNTRIES = "Switzerland";
          FIREWALL_VPN_INPUT_PORTS = "59610";
        };
        envFile = [ config.sops.templates."gluetun.env".path ];
        extra-options = [
          "--cap-add=NET_ADMIN" "--cap-add=NET_RAW"
          "--device=/dev/net/tun:/dev/net/tun"
        ];
        ports = [ "8888:8888" "8388:8388" "59610:59610" "59610:59610/udp" ];
      };
    };

    gluetun-secrets = {config, ...}: {
      sops.secrets."airvpn-wg-key" = {};
      sops.secrets."airvpn-wg-preshared-key" = {};
      sops.templates."gluetun.env" = {
        content = ''
          WIREGUARD_PRIVATE_KEY=${config.sops.placeholder."airvpn-wg-key"}
          WIREGUARD_PRESHARED_KEY=${config.sops.placeholder."airvpn-wg-preshared-key"}
        '';
      };
    };

    rathole = {config, ...}: {
      imports = [self.nixosModules.rathole-secrets];
      services.rathole = {
        enable = true;
        role = "client";
        credentialsFile = config.sops.templates."rathole-credentials.toml".path;
        settings.client = {
          services.sign.local_addr = "127.0.0.1:3000";
          services.share.local_addr = "127.0.0.1:8788";
        };
      };
    };

    rathole-secrets = {config, ...}: {
      sops.secrets."rathole-token" = {};
      sops.secrets."rathole-remote-addr" = {};
      sops.templates."rathole-credentials.toml" = {
        content = /*toml*/ ''
          [client]
          remote_addr = "${config.sops.placeholder."rathole-remote-addr"}"

          [client.services.sign]
          token = "${config.sops.placeholder."rathole-token"}"

          [client.services.share]
          token = "${config.sops.placeholder."rathole-token"}"
        '';
      };
    };

    postfix = {config, pkgs, ...}: {
      imports = [self.nixosModules.postfix-secrets];
      services.postfix = {
        enable = true;
        settings.main = {
          mydomain = "nouritsu.com";
          myorigin = "nouritsu.com";
          mydestination = [];
          mynetworks = [ "127.0.0.0/8" "[::1]/128" "192.168.1.0/24" ];
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
      sops.secrets."home-mail-password" = {};
      sops.templates."mail-sasl-password" = {
        content = "[smtp.hostinger.com]:465 home@nouritsu.com:${config.sops.placeholder."home-mail-password"}";
      };
    };
  };
}
```

### srv/books.nix

Source: `services/books/default.nix`. Module: `srv-bookshelf`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-bookshelf = {config, ...}: let
    endpoint = config.my.endpoints.bookshelf;
  in {
    my.endpoints.bookshelf = { port = 8787; subdomain = "books"; };
    my.containers.bookshelf = {
      enable = true;
      vpn = true;
      ports = ["${toString endpoint.port}:8787"];
      image = { owner = "pennydreadful"; name = "bookshelf"; tag = "hardcover"; provider = "ghcr"; };
      extra-options = ["--user=1000:${toString config.users.groups.data.gid}"];
      vols = ["/data/bookshelf:/config" "/media/download:/data" "/media/media:/media"];
    };
    systemd.tmpfiles.rules = [
      "d /data/bookshelf 0775 1000 data -"
      "d /media/media/books 2775 1000 data -"
    ];
  };
}
```

### srv/cook.nix

Source: `services/cook/default.nix`. Module: `srv-cook-cli`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-cook-cli = {config, ...}: let
    endpoint = config.my.endpoints.cook-cli;
  in {
    my.endpoints.cook-cli = { port = 9080; subdomain = "cook"; };
    services.cook-cli = { enable = true; port = endpoint.port; };
  };
}
```

### srv/disks.nix

Source: `services/disks/default.nix`. Module: `srv-scrutiny`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-scrutiny = {config, ...}: let
    endpoint = config.my.endpoints.scrutiny;
    root = "/dev/nvme0n1";
    hdd-1tb = "/dev/sda";
    hdd-2tb = "/dev/sdb";
  in {
    my.endpoints.scrutiny = { port = 8180; subdomain = "disks"; };
    my.containers.scrutiny = {
      enable = true;
      image = { provider = "ghcr"; owner = "starosdev"; tag = "latest-omnibus"; };
      ports = [ "${toString endpoint.port}:8080" "8187:8086" ];
      vols = [
        "/run/udev:/run/udev:ro"
        "/data/scrutiny/config:/opt/scrutiny/config"
        "/data/scrutiny/influxdb:/opt/scrutiny/influxdb"
      ];
      extra-options = [ "--cap-add=SYS_ADMIN" "--cap-add=SYS_RAWIO" ];
      devices = [hdd-1tb hdd-2tb root];
    };
    systemd.tmpfiles.rules = [
      "d /data/scrutiny 0755 root root -"
      "d /data/scrutiny/config 0755 root root -"
      "d /data/scrutiny/influxdb 0755 root root -"
    ];
  };
}
```

### srv/home.nix

Source: `services/home/default.nix`. Module: `srv-homeassistant`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-homeassistant = {config, ...}: let
    endpoint = config.my.endpoints.home-assistant;
  in {
    my.endpoints.home-assistant = { port = 8123; subdomain = "home"; };
    my.containers.home-assistant = {
      enable = true;
      image = { name = "homeassistant"; provider = "lscr"; };
      vols = [ "/data/homeassistant:/config" "/run/dbus:/run/dbus:ro" "/proc:/host/proc:ro" ];
      ports = [ "${toString endpoint.port}:8123" ];
      extra-options = [ "--net=host" "--cap-add=NET_ADMIN" "--cap-add=NET_RAW" ];
    };
    systemd.tmpfiles.rules = [ "d /data/homeassistant 0775 1000 data -" ];
  };
}
```

### srv/indexes.nix

Source: `services/indexes/default.nix`. Module: `srv-prowlarr`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-prowlarr = {config, ...}: let
    endpoint = config.my.endpoints.prowlarr;
  in {
    my.endpoints.prowlarr = { port = 8084; subdomain = "indexes"; };
    my.containers.prowlarr = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:9696"];
      vols = ["/data/prowlarr:/config"];
    };
    systemd.tmpfiles.rules = [ "d /data/prowlarr 0775 1000 data -" ];
  };
}
```

### srv/mail.nix

Source: `services/mail/default.nix` (roundcube only; postfix moved to services.nix). Module: `srv-roundcube`. No secrets.

```nix
{...}: {
  flake.nixosModules.srv-roundcube = {config, ...}: let
    endpoint = config.my.endpoints.roundcube;
  in {
    my.endpoints.roundcube = { port = 8001; subdomain = "mail"; };
    services.roundcube = {
      enable = true;
      hostName = endpoint.domain;
      extraConfig = ''
        $config['default_host'] = 'ssl://imap.hostinger.com';
        $config['default_port'] = 993;
        $config['smtp_server'] = 'ssl://smtp.hostinger.com';
        $config['smtp_port'] = 465;
        $config['smtp_user'] = '%u';
        $config['smtp_pass'] = '%p';
      '';
    };
    services.nginx.virtualHosts.${endpoint.domain} = {
      listen = [{ addr = "127.0.0.1"; port = endpoint.port; }];
      forceSSL = false;
      enableACME = false;
    };
  };
}
```

### srv/media.nix

Source: `services/media/default.nix`. Module: `srv-jellyseerr`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-jellyseerr = {...}: {
    my.endpoints.jellyseerr = { port = 5055; subdomain = "media"; };
    services.jellyseerr.enable = true;
  };
}
```

### srv/monitor.nix

Source: `services/monitor/default.nix`. Module: `srv-uptime-kuma`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-uptime-kuma = {...}: {
    my.endpoints.uptime-kuma = { port = 4000; subdomain = "monitor"; };
    services.uptime-kuma = { enable = true; settings.PORT = "4000"; };
  };
}
```

### srv/movies.nix

Source: `services/movies/default.nix`. Module: `srv-radarr`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-radarr = {config, ...}: let
    endpoint = config.my.endpoints.radarr;
  in {
    my.endpoints.radarr = { port = 8085; subdomain = "movies"; };
    my.containers.radarr = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:7878"];
      vols = ["/data/radarr:/config" "/media/download:/data" "/media/media:/media"];
    };
    systemd.tmpfiles.rules = [
      "d /data/radarr 0775 1000 data -"
      "d /media/media/movies 2775 1000 data -"
    ];
  };
}
```

### srv/pihole.nix

Source: `services/pihole/default.nix`. Module: `srv-pihole`. No secrets.

```nix
{...}: {
  flake.nixosModules.srv-pihole = {pkgs, config, ...}: let
    TWELVE_HOURS_SECONDS = 43200;
  in {
    my.endpoints.pihole.port = 8081;
    environment.systemPackages = [pkgs.pihole-ftl];
    networking = {
      useDHCP = false;
      interfaces.end0.useDHCP = true;
      nameservers = ["127.0.0.1"];
    };
    services.resolved = {
      enable = true;
      extraConfig = ''
        DNSStubListener=no
        MulticastDNS=off
      '';
    };
    services.pihole-ftl = {
      enable = true;
      openFirewallDNS = true;
      openFirewallWebserver = true;
      useDnsmasqConfig = true;
      lists = [
        {
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro.plus.txt";
          type = "block";
          enabled = true;
          description = "Hagezi Pro Plus";
        }
      ];
      settings = {
        dns = {
          bind_hosts = ["192.168.178.128" "127.0.0.1"];
          interface = "end0";
          upstreams = [ "1.1.1.1" "1.0.0.1" ];
          domainNeeded = true;
          expandHosts = true;
          hosts = [
            "192.168.178.1   gateway"
            "192.168.178.128   pihole"
          ];
        };
        dhcp.active = false;
        webserver = {
          api = { /* TODO: add passwords */ };
          session.timeout = TWELVE_HOURS_SECONDS;
        };
        ntp = {
          ipv4.active = false;
          ipv6.active = false;
          sync.active = false;
        };
      };
    };
    services.pihole-web = {
      enable = true;
      ports = [config.my.endpoints.pihole.port];
    };
  };
}
```

### srv/player.nix

Source: `services/player/default.nix`. Module: `srv-jellyfin`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-jellyfin = {config, ...}: let
    endpoint = config.my.endpoints.jellyfin;
  in {
    my.endpoints.jellyfin = { port = 8096; subdomain = "player"; };
    my.containers.jellyfin = {
      enable = true;
      ports = ["${toString endpoint.port}:8096"];
      dri-passthrough = true;
      image = { name = "jellyfin"; provider = "lscr"; };
      vols = ["/data/jellyfin:/config" "/media/media:/media:ro"];
    };
    systemd.tmpfiles.rules = [ "d /data/jellyfin 0775 1000 data -" ];
  };
}
```

### srv/shows.nix

Source: `services/shows/default.nix`. Module: `srv-sonarr`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-sonarr = {config, ...}: let
    endpoint = config.my.endpoints.sonarr;
  in {
    my.endpoints.sonarr = { port = 8086; subdomain = "shows"; };
    my.containers.sonarr = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:8989"];
      vols = ["/data/sonarr:/config" "/media/download:/data" "/media/media:/media"];
    };
    systemd.tmpfiles.rules = [
      "d /data/sonarr 0775 1000 data -"
      "d /media/media/shows 2775 1000 data -"
    ];
  };
}
```

### srv/speed.nix

Source: `services/speed/default.nix`. Module: `srv-myspeed`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-myspeed = {config, ...}: let
    endpoint = config.my.endpoints.myspeed;
  in {
    my.endpoints.myspeed = { port = 5216; subdomain = "speed"; };
    my.containers.myspeed = {
      enable = true;
      image = { owner = "germannewsmaker"; provider = "official"; };
      ports = ["${toString endpoint.port}:5216"];
      vols = [ "/data/myspeed:/myspeed/data" ];
    };
    systemd.tmpfiles.rules = [ "d /data/myspeed 0775 1000 data -" ];
  };
}
```

### srv/sync.nix

Source: `services/sync/default.nix`. Module: `srv-syncthing`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-syncthing = {config, ...}: let
    endpoint = config.my.endpoints.syncthing;
  in {
    my.endpoints.syncthing = { port = 8384; subdomain = "sync"; };
    services.syncthing = {
      enable = true;
      guiAddress = "127.0.0.1:${toString endpoint.port}";
      openDefaultPorts = true;
      settings = {
        gui = {
          user = "admin";
          password = "$2y$05$E2gP6TBFqPr9Q3KK7aCFyeXoBhPntwbGbw6GRO9et1zr2LnPqaqAy";
          insecureSkipHostCheck = true;
        };
        devices = {
          "pixel-9-pro-xl" = {
            id = "SOVMGB6-3POHJZL-XRFCGTU-VW4CCDZ-VJ6OVYV-Z4UTOIV-BYLLRYK-RQMFVQW";
            autoAcceptFolders = true;
          };
          "pc" = {
            id = "U5KKTMD-AXRIBAB-GVLY3JA-BHO42R7-HMBOBYF-SSWISQM-UQ2SCRC-3CPHXQI";
            autoAcceptFolders = true;
          };
          "iphone" = {
            id = "U7FERHJ-XOAXOGC-HQSAZCN-U443QJZ-KVSF2VU-7JJ2QAB-MOLC6F7-JHREAAC";
            autoAcceptFolders = true;
          };
        };
        folders = {
          "phone-scanned-docs" = {
            path = "/var/lib/paperless/consume";
            devices = ["pixel-9-pro-xl"];
            type = "receiveonly";
          };
          "pc-cook-cli-base" = {
            path = "/var/lib/cook-cli";
            devices = ["pc"];
            type = "receiveonly";
          };
          "homelab-cook-cli-base" = {
            path = "/var/lib/cook-cli";
            devices = ["iphone"];
            type = "sendreceive";
          };
        };
      };
    };
    systemd.services.syncthing.serviceConfig.SupplementaryGroups = ["paperless" "users" "data"];
  };
}
```

### srv/torrent.nix

Source: `services/torrent/default.nix`. Module: `srv-qbittorrent`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-qbittorrent = {config, ...}: let
    endpoint = config.my.endpoints.torrent;
  in {
    my.endpoints.torrent.port = 8082;
    my.containers.qbittorrent = {
      enable = true;
      vpn = true;
      image.provider = "lscr";
      ports = ["${toString endpoint.port}:8081"];
      env = { WEBUI_PORT = "8081"; TORRENTING_PORT = "59610"; };
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
}
```

### srv/usenet.nix

Source: `services/usenet/default.nix`. Module: `srv-sabnzbd`. No secrets, no db.

```nix
{...}: {
  flake.nixosModules.srv-sabnzbd = {config, ...}: let
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
  };
}
```

### srv/docs.nix

Source: `services/docs/default.nix`. Modules: `srv-paperless` + `paperless-secrets`.

```nix
{self, ...}: {
  flake.nixosModules = {
    srv-paperless = {config, ...}: let
      endpoint = config.my.endpoints.paperless;
    in {
      imports = [self.nixosModules.paperless-secrets];
      my.endpoints.paperless = { port = 28981; subdomain = "docs"; };
      services.gotenberg.port = 3001;
      services.paperless = {
        enable = true;
        consumptionDirIsPublic = true;
        port = endpoint.port;
        domain = endpoint.domain;
        passwordFile = config.sops.secrets.paperless-admin-password.path;
        configureTika = true;
        settings = {
          PAPERLESS_OCR_LANGUAGE = "eng+deu";
          PAPERLESS_TIME_ZONE = "Europe/Berlin";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:3001";
        };
      };
    };

    paperless-secrets = {...}: {
      sops.secrets."paperless-admin-password" = {};
    };
  };
}
```

### srv/download.nix

Source: `services/download/default.nix`. Modules: `srv-aria2` + `aria2-secrets`.

```nix
{self, ...}: {
  flake.nixosModules = {
    srv-aria2 = {config, ...}: let
      endpoint = config.my.endpoints.download;
    in {
      imports = [self.nixosModules.aria2-secrets];
      my.endpoints.download = { port = 6880; subdomain = "download"; };
      my.endpoints.aria2 = { port = 6800; subdomain = "aria2"; };
      my.containers.aria2-pro = {
        enable = true;
        vpn = true;
        image = { provider = "official"; owner = "p3terx"; name = "aria2-pro"; };
        ports = ["6800:6800"];
        env = { PUID = "1000"; PGID = "1000"; UPDATE_TRACKERS = "false"; };
        envFile = [ config.sops.templates."aria2.env".path ];
        vols = [ "/data/ariang/config:/config" "/media/download/aria2:/downloads" ];
        extra-options = [ "--log-driver=json-file" "--log-opt=max-size=1m" ];
      };
      my.containers.ariang = {
        enable = true;
        image = { provider = "official"; owner = "p3terx"; name = "ariang"; };
        ports = ["${toString endpoint.port}:6880"];
        extra-options = [ "--log-driver=json-file" "--log-opt=max-size=1m" ];
      };
      systemd.tmpfiles.rules = [
        "d /data/ariang 0775 1000 data -"
        "d /data/ariang/config 0775 1000 data -"
        "d /media/download/aria2 2775 1000 data -"
      ];
    };

    aria2-secrets = {config, ...}: {
      sops.secrets."aria2-rpc" = {};
      sops.templates."aria2.env" = {
        content = ''
          RPC_SECRET=${config.sops.placeholder."aria2-rpc"}
        '';
      };
    };
  };
}
```

### srv/share.nix

Source: `services/share/default.nix` + `secrets.nix`. Modules: `srv-enclosed` + `enclosed-secrets`. No endpoint (exposed via rathole).

```nix
{self, ...}: {
  flake.nixosModules = {
    srv-enclosed = {config, ...}: let
      port = "8788";
    in {
      imports = [self.nixosModules.enclosed-secrets];
      my.containers.enclosed = {
        enable = true;
        image = { provider = "official"; owner = "corentinth"; };
        ports = ["${port}:8787"];
        env.PUBLIC_IS_AUTHENTICATION_REQUIRED = "true";
        envFile = [ config.sops.templates."enclosed.env".path ];
        vols = [ "/data/enclosed:/app/.data" ];
      };
      systemd.tmpfiles.rules = [ "d /data/enclosed 0775 1000 data -" ];
    };

    enclosed-secrets = {config, ...}: {
      sops.secrets."enclosed-jwt-secret" = {};
      sops.secrets."enclosed-auth-users" = {};
      sops.templates."enclosed.env" = {
        content = ''
          AUTHENTICATION_JWT_SECRET=${config.sops.placeholder."enclosed-jwt-secret"}
          AUTHENTICATION_USERS=${config.sops.placeholder."enclosed-auth-users"}
        '';
      };
    };
  };
}
```

### srv/vault.nix

Source: `services/vault/default.nix`. Modules: `srv-vaultwarden` + `vaultwarden-secrets`.

```nix
{self, ...}: {
  flake.nixosModules = {
    srv-vaultwarden = {config, ...}: let
      endpoint = config.my.endpoints.vaultwarden;
    in {
      imports = [self.nixosModules.vaultwarden-secrets];
      my.endpoints.vaultwarden = { port = 8087; subdomain = "vault"; };
      services.vaultwarden = {
        enable = true;
        environmentFile = config.sops.templates."vaultwarden.env".path;
        config = {
          DOMAIN = "https://${endpoint.domain}";
          SIGNUPS_ALLOWED = false;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = endpoint.port;
        };
      };
    };

    vaultwarden-secrets = {config, ...}: {
      sops.secrets."vaultwarden-admin-token" = {};
      sops.templates."vaultwarden.env" = {
        owner = "vaultwarden";
        content = ''
          ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}
        '';
      };
    };
  };
}
```

### srv/vpn.nix

Source: `services/vpn/default.nix`. Modules: `srv-wg-easy` + `wg-easy-secrets`.

```nix
{self, ...}: {
  flake.nixosModules = {
    srv-wg-easy = {config, ...}: let
      wg-port = 51820;
      data-dir = "/data/wg-easy";
      endpoint = config.my.endpoints.wg-easy;
    in {
      imports = [self.nixosModules.wg-easy-secrets];
      my.endpoints.wg-easy = { port = 51821; subdomain = "vpn"; };
      my.containers.wg-easy = {
        enable = true;
        image = { tag = "15"; provider = "ghcr"; };
        env = {
          INIT_ENABLED = "true";
          INIT_USERNAME = "admin";
          INIT_DNS = "${config.my.net.ip},1.1.1.1";
          WG_POST_UP = "";
          WG_POST_DOWN = "";
        };
        envFile = [ config.sops.templates."wg-easy.env".path ];
        vols = [
          "${data-dir}:/etc/wireguard"
          "/run/booted-system/kernel-modules/lib/modules:/lib/modules:ro"
        ];
        extra-options = [ "--privileged" "--network=host" ];
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
      systemd.tmpfiles.rules = [ "d ${data-dir} 0700 root root -" ];
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
```

### srv/photos.nix

Source: `services/photos/{default,secrets,postgres}.nix`. Modules: `srv-immich` + `immich-secrets` + `immich-db` + `immich-db-secrets`.

Note: `immich-secrets` references `config.sops.placeholder."postgres-password"` which is declared in `immich-db-secrets`. This works because `srv-immich` imports both `immich-secrets` and `immich-db` (which imports `immich-db-secrets`), and NixOS config merging is lazy/declarative.

```nix
{self, ...}: {
  flake.nixosModules = {
    srv-immich = {config, ...}: let
      endpoint = config.my.endpoints.immich;
    in {
      imports = [
        self.nixosModules.immich-secrets
        self.nixosModules.immich-db
      ];
      my.endpoints.immich = { port = 2283; subdomain = "photos"; };
      my.containers.immich-server = {
        enable = true;
        image.url = "ghcr.io/immich-app/immich-server:release";
        ports = ["${toString endpoint.port}:2283"];
        envFile = [ config.sops.templates."immich.env".path ];
        vols = [ "/data/immich/upload:/data" "/etc/localtime:/etc/localtime:ro" ];
        dri-passthrough = true;
        extra-options = [
          "--add-host=immich-db:host-gateway"
          "--add-host=immich-redis:host-gateway"
          "--add-host=immich-ml:host-gateway"
        ];
      };
      my.containers.immich-ml = {
        enable = true;
        image.url = "ghcr.io/immich-app/immich-machine-learning:release";
        ports = ["3003:3003"];
        vols = [ "immich-ml-cache:/cache" ];
        envFile = [ config.sops.templates."immich.env".path ];
      };
      my.containers.immich-redis = {
        enable = true;
        image.url = "docker.io/valkey/valkey:9";
        ports = ["6379:6379"];
        extra-options = [
          "--health-cmd=redis-cli ping || exit 1"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };
      virtualisation.oci-containers.containers.immich-server.dependsOn = ["immich-redis" "immich-db"];
      virtualisation.oci-containers.containers.immich-server.environment = {
        IMMICH_MACHINE_LEARNING_URL = "http://immich-ml:3003";
      };
      systemd.tmpfiles.rules = [
        "d /data/immich 0775 1000 data -"
        "d /data/immich/upload 0775 1000 data -"
      ];
    };

    immich-secrets = {config, ...}: {
      sops.templates."immich.env" = {
        content = ''
          DB_PASSWORD=${config.sops.placeholder."postgres-password"}
          DB_HOSTNAME=immich-db
          DB_PORT=5434
          DB_USERNAME=immich
          DB_DATABASE_NAME=immich
          REDIS_HOSTNAME=immich-redis
          REDIS_PORT=6379
        '';
      };
    };

    immich-db = {config, ...}: {
      imports = [self.nixosModules.immich-db-secrets];
      my.containers.immich-db = {
        enable = true;
        image.url = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
        env = {
          POSTGRES_USER = "immich";
          POSTGRES_DB = "immich";
          POSTGRES_INITDB_ARGS = "--data-checksums";
          PGPORT = "5434";
        };
        envFile = [ config.sops.templates."immich-postgres.env".path ];
        vols = [ "immich-db:/var/lib/postgresql/data" ];
        ports = ["5434:5434"];
        extra-options = [
          "--shm-size=128m"
          "--health-cmd=pg_isready -U immich -p 5434"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };
    };

    immich-db-secrets = {config, ...}: {
      sops.secrets."postgres-password" = {};
      sops.templates."immich-postgres.env" = {
        content = ''
          POSTGRES_PASSWORD=${config.sops.placeholder."postgres-password"}
        '';
      };
    };
  };
}
```

### srv/sign.nix

Source: `services/sign/{default,secrets,postgres}.nix`. Modules: `srv-documenso` + `documenso-secrets` + `documenso-db` + `documenso-db-secrets`.

Notes:
- `documenso-secrets` references `config.sops.placeholder."home-mail-password"` (owned by `postfix-secrets`) and `config.sops.placeholder."postgres-password"` (owned by `documenso-db-secrets`). Host must include `postfix` for the mail password to be available.
- `documenso-cert` lives in the global `secrets` module (`modules/secrets/secrets.nix`), not here.
- Rename template from `"postgres.env"` to `"documenso-postgres.env"` to avoid future collisions.

```nix
{self, ...}: {
  flake.nixosModules = {
    srv-documenso = {config, ...}: let
      smtp-host = "smtp.hostinger.com";
      smtp-port = 465;
    in {
      imports = [
        self.nixosModules.documenso-secrets
        self.nixosModules.documenso-db
      ];
      my.containers.documenso = {
        enable = true;
        image.provider = "official";
        ports = ["3000:3000"];
        env = {
          NEXT_PRIVATE_SMTP_HOST = smtp-host;
          NEXT_PRIVATE_SMTP_PORT = toString smtp-port;
          NEXT_PRIVATE_SMTP_USERNAME = "home@nouritsu.com";
          NEXT_PRIVATE_SMTP_FROM_ADDRESS = "sign@nouritsu.com";
          NEXT_PRIVATE_SMTP_SECURE = "true";
          PORT = "3000";
          NEXTAUTH_URL = "https://sign.nouritsu.com";
          NEXT_PUBLIC_WEBAPP_URL = "https://sign.nouritsu.com";
          NEXT_PRIVATE_INTERNAL_WEBAPP_URL = "http://localhost:3000";
          NEXT_PRIVATE_SMTP_TRANSPORT = "smtp-auth";
          NEXT_PRIVATE_SMTP_FROM_NAME = "Documenso";
          NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH = "/opt/documenso/cert.p12";
          NEXT_PUBLIC_DISABLE_SIGNUP = "true";
          DOCUMENSO_DISABLE_TELEMETRY = "true";
        };
        envFile = [ config.sops.templates."documenso.env".path ];
        vols = [ "${config.sops.secrets."documenso-cert".path}:/opt/documenso/cert.p12:ro" ];
        extra-options = [ "--add-host=documenso-db:host-gateway" ];
      };
      virtualisation.oci-containers.containers.documenso.dependsOn = ["documenso-db"];
    };

    documenso-secrets = {config, ...}: {
      sops.secrets."nextauth-secret" = {};
      sops.secrets."next-key" = {};
      sops.secrets."next-secondary-key" = {};
      sops.secrets."next-signing-pass" = {};
      sops.templates."documenso.env" = {
        content = ''
          NEXTAUTH_SECRET=${config.sops.placeholder."nextauth-secret"}
          NEXT_PRIVATE_ENCRYPTION_KEY=${config.sops.placeholder."next-key"}
          NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=${config.sops.placeholder."next-secondary-key"}
          NEXT_PRIVATE_SIGNING_PASSPHRASE=${config.sops.placeholder."next-signing-pass"}
          NEXT_PRIVATE_SMTP_PASSWORD=${config.sops.placeholder."home-mail-password"}
          NEXT_PRIVATE_DATABASE_URL=postgresql://documenso:${config.sops.placeholder."postgres-password"}@documenso-db:5433/documenso
          NEXT_PRIVATE_DIRECT_DATABASE_URL=postgresql://documenso:${config.sops.placeholder."postgres-password"}@documenso-db:5433/documenso
        '';
      };
    };

    documenso-db = {config, ...}: {
      imports = [self.nixosModules.documenso-db-secrets];
      my.containers.documenso-db = {
        enable = true;
        image.url = "postgres:15";
        env = { POSTGRES_USER = "documenso"; POSTGRES_DB = "documenso"; };
        envFile = [ config.sops.templates."documenso-postgres.env".path ];
        vols = [ "documenso-db:/var/lib/postgresql/data" ];
        ports = ["5433:5432"];
        extra-options = [
          "--health-cmd=pg_isready -U documenso"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };
    };

    documenso-db-secrets = {config, ...}: {
      sops.secrets."postgres-password" = {};
      sops.templates."documenso-postgres.env" = {
        content = ''
          POSTGRES_PASSWORD=${config.sops.placeholder."postgres-password"}
        '';
      };
    };
  };
}
```

## Host Config Update

Replace `++ [../../modules];` in `hosts/homelab/homelab.nix` with explicit module list:

```nix
modules = with self.nixosModules;
  [
    homelab-system
    homelab-disko
    secrets
    opts

    # system
    graphics
    audio
    locale
    auto-tz
    network
    storage
    fs-xfs
    fs-btrfs
    user-aneesh
    virt-podman

    # ssh
    ssh-base
    ssh-from-pc
    ssh-from-phone

    # nix
    nix-base
    nix-cache
    nixpkgs-unfree

    # applications
    app-core
    app-fish
    app-nh

    # infrastructure
    caddy
    gluetun
    rathole
    postfix

    # services
    srv-openrgb
    srv-bookshelf
    srv-cook-cli
    srv-scrutiny
    srv-paperless
    srv-aria2
    srv-homeassistant
    srv-prowlarr
    srv-roundcube
    srv-jellyseerr
    srv-uptime-kuma
    srv-radarr
    srv-immich
    srv-pihole
    srv-jellyfin
    srv-enclosed
    srv-sonarr
    srv-documenso
    srv-myspeed
    srv-syncthing
    srv-qbittorrent
    srv-sabnzbd
    srv-vaultwarden
    srv-wg-easy
  ];
```

## Cleanup

After all services are migrated and verified:
1. Delete `modules/services/` directory entirely
2. Delete `modules/default.nix`

## Implementation Order

1. Add `(import-tree ./modules/srv)` to `flake.nix`
2. Create all `modules/srv/*.nix` files
3. Update `hosts/homelab/homelab.nix` - replace `++ [../../modules]` with explicit list
4. Delete `modules/services/` and `modules/default.nix`

## Verification

```bash
nix flake check
nix build .#nixosConfigurations.homelab.config.system.build.toplevel
```

## Notable Dependencies

- `srv-documenso` requires `postfix` in host config (for `home-mail-password` sops placeholder)
- `documenso-cert` secret stays in global `modules/secrets/secrets.nix`
- Both `immich-db-secrets` and `documenso-db-secrets` declare `sops.secrets."postgres-password" = {}` (idempotent merge)
