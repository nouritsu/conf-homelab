{
  den.aspects.postfix.nixos = {
    config,
    pkgs,
    ...
  }: {
    sops.secrets."mail/home-password" = {};
    sops.secrets."mail/home-mail" = {};
    sops.templates."mail-sasl-password" = {
      content = "[smtp.hostinger.com]:465 ${config.sops.placeholder."mail/home-mail"}:${config.sops.placeholder."mail/home-password"}";
    };

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
}
