{
  flake.nixosModules.srv-roundcube = {config, ...}: let
    endpoint = config.my.endpoints.roundcube;
  in {
    my.endpoints.roundcube = {
      enable = true;
      tlsInternal = true;
      port = 8001;
      subdomain = "mail";
    };
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
      listen = [
        {
          addr = "127.0.0.1";
          port = endpoint.port;
        }
      ];
      forceSSL = false;
      enableACME = false;
    };
  };
}
