{self, ...}: {
  flake.nixosModules = {
    srv-paperless = {config, ...}: let
      inherit (self.lib) endpoint fqdn;
      port = 28981;
    in {
      imports = [
        self.nixosModules.paperless-secrets
        (endpoint {
          subdomain = "docs";
          inherit port;
        })
      ];

      services.gotenberg.port = 3001;
      services.paperless = {
        enable = true;
        consumptionDirIsPublic = true;
        inherit port;
        domain = fqdn "docs";
        passwordFile = config.sops.secrets."paperless/admin-password".path;
        configureTika = true;
        settings = {
          PAPERLESS_OCR_LANGUAGE = "eng+deu";
          PAPERLESS_TIME_ZONE = "Europe/Berlin";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:3001";
        };
      };
    };

    paperless-secrets = {...}: {
      sops.secrets."paperless/admin-password" = {};
    };
  };
}
