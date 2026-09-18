{den, ...}: let
  port = 8087;
in {
  den.aspects.srv-vaultwarden = {
    endpoint = {
      subdomain = "vault";
      inherit port;
    };

    nixos = {config, ...}: {
      sops.secrets."vaultwarden/admin-token" = {};
      sops.templates."vaultwarden.env" = {
        owner = "vaultwarden";
        content = ''
          ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin-token"}
        '';
      };

      services.vaultwarden = {
        enable = true;
        environmentFile = config.sops.templates."vaultwarden.env".path;
        config = {
          DOMAIN = "https://${den.lib.homelab.fqdn "vault"}";
          SIGNUPS_ALLOWED = false;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = port;
        };
      };
    };
  };
}
