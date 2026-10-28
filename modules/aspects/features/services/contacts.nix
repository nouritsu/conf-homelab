{den, ...}: let
  inherit (den.lib.homelab) base-domain;

  # radicale's own default; left unset so the module keeps it on localhost
  port = 5232;
  collections = "/var/lib/radicale/collections";
in {
  den.aspects.services.radicale = {
    endpoint = {
      subdomain = "contacts";
      inherit port;
    };
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
      sops.secrets."birthdays/ssh-key" = {};

      services.radicale = {
        enable = true;
        settings.auth = {
          type = "htpasswd";
          htpasswd_filename = config.sops.secrets."radicale/htpasswd".path;
          htpasswd_encryption = "bcrypt";
        };
      };

      programs.ssh.knownHosts.${base-domain}.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfueKWTRGtY20+RWrRPJHPvo1CmKOd0T/YJ9nbOXk4Q";

      # the contacts' dates, for edge.birthdays on the vps to serve
      systemd.services.birthdays = {
        description = "Push the contacts' birthdays to the vps";
        wants = ["network-online.target"];
        after = ["network-online.target" "radicale.service"];
        path = [pkgs.openssh];

        script = ''
          set -o pipefail
          ${lib.getExe birthdays} ${collections} \
            | ssh -T -i "$CREDENTIALS_DIRECTORY/ssh-key" -o IdentitiesOnly=yes -o BatchMode=yes \
              -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null birthdays@${base-domain}
        '';

        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          # radicale's storage is group-readable
          SupplementaryGroups = ["radicale"];
          LoadCredential = ["ssh-key:${config.sops.secrets."birthdays/ssh-key".path}"];

          PrivateTmp = true;
          PrivateDevices = true;
          NoNewPrivileges = true;
          RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        };
      };

      systemd.timers.birthdays = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
      };
    };
  };
}
