let
  # radicale's own default; left unset so the module keeps it on localhost
  port = 5232;
  feed-port = 8089;
  collections = "/var/lib/radicale/collections";
  state-dir = "/var/lib/birthdays";
in {
  den.aspects.services.radicale = {
    endpoint = [
      {
        subdomain = "contacts";
        inherit port;
      }
      # only a tunnel: edge.birthdays proxies cal.nouritsu.com's feed path to it
      {
        subdomain = "birthdays";
        port = feed-port;
        public = true;
        vhost = false;
      }
    ];
    backup.paths = [collections];

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      birthdays = pkgs.writers.writePython3Bin "birthdays" {
        libraries = [pkgs.python3Packages.icalendar];
        flakeIgnore = ["E501"];
      } (builtins.readFile ./birthdays.py);
    in {
      sops.secrets."radicale/htpasswd".owner = "radicale";
      sops.secrets."birthdays/feed-token" = {};

      services.radicale = {
        enable = true;
        settings.auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.secrets."radicale/htpasswd".path;
          htpasswd_encryption = "bcrypt";
        };
      };

      # static rather than DynamicUser: caddy can't reach /var/lib/private
      users.users.birthdays = {
        isSystemUser = true;
        group = "birthdays";
      };
      users.groups.birthdays = {};

      # the contacts' dates as an ics feed, regenerated hourly
      systemd.services.birthdays = {
        description = "Publish the contacts' birthdays as an ics feed";
        after = ["radicale.service"];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe birthdays} ${collections} --feeds ${state-dir}/feeds";
          User = "birthdays";
          Group = "birthdays";
          # radicale's storage is group-readable
          SupplementaryGroups = ["radicale"];
          LoadCredential = ["feed-token:${config.sops.secrets."birthdays/feed-token".path}"];

          # 0711: caddy can open the token's path, nobody can list it
          StateDirectory = "birthdays";
          StateDirectoryMode = "0711";

          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateNetwork = true;
          NoNewPrivileges = true;
        };
      };

      systemd.timers.birthdays = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };

      # the tunnel's end; the secret token is a directory name, so it never appears here
      services.caddy.virtualHosts."http://:${toString feed-port}" = {
        listenAddresses = ["127.0.0.1"];
        extraConfig = ''
          root * ${state-dir}/feeds
          file_server
        '';
      };
    };
  };
}
