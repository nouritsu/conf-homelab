{self, ...}: {
  flake.nixosModules = {
    srv-paperless = {config, ...}: let
      endpoint = config.my.endpoints.paperless;
    in {
      imports = [self.nixosModules.paperless-secrets];
      my.endpoints.paperless = {
        port = 28981;
        subdomain = "docs";
      };
      services.gotenberg.port = 3001;
      services.paperless = {
        enable = true;
        consumptionDirIsPublic = true;
        port = endpoint.port;
        domain = endpoint.domain;
        passwordFile = config.sops.secrets.paperless-admin-password.path;
        configureTika = true;
        settings = {
          PAPERLESS_OCR_LANGUAGE = "eng+deu";
          PAPERLESS_TIME_ZONE = "Europe/Berlin";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:3001";
        };
      };
    };

    paperless-secrets = {...}: {
      sops.secrets."paperless-admin-password" = {};
    };
  };
}
