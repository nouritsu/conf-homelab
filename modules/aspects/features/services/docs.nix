{den, ...}: let
  port = 28981;
in {
  den.aspects.services.paperless = {
    endpoint = {
      subdomain = "docs";
      inherit port;
    };

    nixos = {config, ...}: {
      sops.secrets."paperless/admin-password" = {};

      services.gotenberg.port = 3001;
      services.paperless = {
        enable = true;
        consumptionDirIsPublic = true;
        inherit port;
        domain = den.lib.homelab.fqdn "docs";
        passwordFile = config.sops.secrets."paperless/admin-password".path;
        configureTika = true;
        settings = {
          PAPERLESS_OCR_LANGUAGE = "eng+deu";
          PAPERLESS_TIME_ZONE = "Europe/Berlin";
          PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://localhost:3001";
        };
      };
    };
  };
}
