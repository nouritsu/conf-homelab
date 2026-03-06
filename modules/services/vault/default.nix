{config, ...}: let
  endpoint = config.my.endpoints.vaultwarden;
in {
  my.endpoints.vaultwarden = {
    port = 8087;
    subdomain = "vault";
  };

  sops.secrets."vaultwarden-admin-token" = {};
  sops.templates."vaultwarden.env" = {
    owner = "vaultwarden";
    content = ''
      ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}
    '';
  };
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
}
