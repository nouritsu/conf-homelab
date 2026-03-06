{
  config,
  pkgs,
  ...
}: let
  smtp-host = "smtp.hostinger.com";
  smtp-port = 465;
  domain = "nouritsu.com";
in {
  sops.secrets."home-mail-password" = {};
  sops.templates."mail-sasl-password" = {
    content = "[${smtp-host}]:${toString smtp-port} home@${domain}:${config.sops.placeholder."home-mail-password"}";
  };
  services.postfix = {
    enable = true;
    settings.main = {
      mydomain = domain;
      myorigin = domain;
      mydestination = [];
      mynetworks = [
        "127.0.0.0/8"
        "[::1]/128"
        "192.168.1.0/24"
      ];
      relayhost = ["[${smtp-host}]:${toString smtp-port}"];
      smtp_tls_security_level = "encrypt";
      smtp_tls_wrappermode = "yes";
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_password_maps = "texthash:${config.sops.templates."mail-sasl-password".path}";
      smtp_sasl_security_options = "noanonymous";
      inet_interfaces = "loopback-only";
    };
  };
  environment.systemPackages = [pkgs.mailutils];
}
