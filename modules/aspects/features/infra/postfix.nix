{den, ...}: {
  den.aspects.postfix.nixos = {
    config,
    pkgs,
    ...
  }: let
    inherit (den.lib.homelab) base-domain lan-cidr smtp;
    relay = "[${smtp.host}]:${toString smtp.port}";
  in {
    sops.secrets."mail/home-password" = {};
    sops.secrets."mail/home-mail" = {};
    sops.templates."mail-sasl-password" = {
      content = "${relay} ${config.sops.placeholder."mail/home-mail"}:${config.sops.placeholder."mail/home-password"}";
    };

    services.postfix = {
      enable = true;
      settings.main = {
        mydomain = base-domain;
        myorigin = base-domain;
        mydestination = [];
        mynetworks = ["127.0.0.0/8" "[::1]/128" lan-cidr];
        relayhost = [relay];
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
}
