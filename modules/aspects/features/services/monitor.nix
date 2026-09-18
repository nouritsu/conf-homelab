{den, ...}: {
  den.aspects.srv-beszel.nixos = {config, ...}: let
    inherit (den.lib.homelab) endpoint;
    port = 8090;
  in {
    imports = [
      (endpoint {
        subdomain = "monitor";
        inherit port;
      })
    ];

    sops.secrets."beszel/token" = {};
    sops.secrets."beszel/key" = {};

    sops.templates."beszel.env" = {
      content = ''
        HUB_URL="http://localhost:8090"
        KEY="${config.sops.placeholder."beszel/key"}"
        TOKEN="${config.sops.placeholder."beszel/token"}"
      '';
    };

    services.beszel = {
      hub.enable = true;

      agent.enable = true;
      agent.environmentFile = config.sops.templates."beszel.env".path;
    };
  };
}
