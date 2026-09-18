{den, ...}: {
  den.aspects.srv-vaultwarden.nixos = {config, ...}: let
    inherit (den.lib.homelab) endpoint fqdn;
    port = 8087;
  in {
    imports = [
      (endpoint {
        subdomain = "vault";
        inherit port;
      })
    ];

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
        DOMAIN = "https://${fqdn "vault"}";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = port;
      };
    };
  };
}
