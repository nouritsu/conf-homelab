{self, ...}: {
  flake.nixosModules = {
    srv-vaultwarden = {config, ...}: let
      endpoint = config.my.endpoints.vaultwarden;
    in {
      imports = [self.nixosModules.vaultwarden-secrets];
      my.endpoints.vaultwarden = {
        port = 8087;
        subdomain = "vault";
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
    };

    vaultwarden-secrets = {config, ...}: {
      sops.secrets."vaultwarden-admin-token" = {};
      sops.templates."vaultwarden.env" = {
        owner = "vaultwarden";
        content = ''
          ADMIN_TOKEN=${config.sops.placeholder.vaultwarden-admin-token}
        '';
      };
    };
  };
}
