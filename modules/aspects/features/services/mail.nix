{den, ...}: let
  inherit (den.lib.homelab) imap smtp;

  domain = den.lib.homelab.fqdn "mail";
  port = 8001;
in {
  den.aspects.srv-roundcube = {
    endpoint = {
      subdomain = "mail";
      inherit port;
    };

    nixos = {
      services.roundcube = {
        enable = true;
        hostName = domain;
        extraConfig = ''
          $config['default_host'] = 'ssl://${imap.host}';
          $config['default_port'] = ${toString imap.port};
          $config['smtp_server'] = 'ssl://${smtp.host}';
          $config['smtp_port'] = ${toString smtp.port};
          $config['smtp_user'] = '%u';
          $config['smtp_pass'] = '%p';
        '';
      };
      services.nginx.virtualHosts.${domain} = {
        listen = [
          {
            addr = "127.0.0.1";
            inherit port;
          }
        ];
        forceSSL = false;
        enableACME = false;
      };
    };
  };
}
