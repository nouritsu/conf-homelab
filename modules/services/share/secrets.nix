{config, ...}: {
  sops.secrets."enclosed-jwt-secret" = {};
  sops.secrets."enclosed-auth-users" = {};

  sops.templates."enclosed.env" = {
    content = ''
      AUTHENTICATION_JWT_SECRET=${config.sops.placeholder."enclosed-jwt-secret"}
      AUTHENTICATION_USERS=${config.sops.placeholder."enclosed-auth-users"}
    '';
  };
}
