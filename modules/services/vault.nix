{self, ...}: {
  flake.nixosModules = {
    srv-vaultwarden = {config, ...}: let
      inherit (self.lib) endpoint fqdn;
      port = 8087;
    in {
      imports = [
        self.nixosModules.vaultwarden-secrets
        (endpoint {
          subdomain = "vault";
          inherit port;
        })
      ];

      services.vaultwarden = {
        enable = true;
        environmentFile = config.sops.templates."vaultwarden.env".path;
        config = {
          DOMAIN = "https://${fqdn "vault"}";
          SIGNUPS_ALLOWED = false;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = port;
        };
      };
    };

    vaultwarden-secrets = {config, ...}: {
      sops.secrets."vaultwarden/admin-token" = {};
      sops.templates."vaultwarden.env" = {
        owner = "vaultwarden";
        content = ''
          ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
        '';
      };
    };
  };
}
