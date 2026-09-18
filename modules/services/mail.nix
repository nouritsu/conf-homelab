{self, ...}: {
  flake.nixosModules.srv-roundcube = {...}: let
    inherit (self.lib) endpoint fqdn;
    domain = fqdn "mail";
    port = 8001;
  in {
    imports = [
      (endpoint {
        subdomain = "mail";
        inherit port;
      })
    ];

    services.roundcube = {
      enable = true;
      hostName = domain;
      extraConfig = ''
        $config['default_host'] = 'ssl://imap.hostinger.com';
        $config['default_port'] = 993;
        $config['smtp_server'] = 'ssl://smtp.hostinger.com';
        $config['smtp_port'] = 465;
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
}
