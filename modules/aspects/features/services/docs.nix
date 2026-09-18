{den, ...}: {
  den.aspects.srv-paperless.nixos = {config, ...}: let
    inherit (den.lib.homelab) endpoint fqdn;
    port = 28981;
  in {
    imports = [
      (endpoint {
        subdomain = "docs";
        inherit port;
      })
    ];

    sops.secrets."paperless/admin-password" = {};

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
}
