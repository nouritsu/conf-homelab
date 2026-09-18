{
  den.aspects.srv-beszel = let
    port = 8090;
  in {
    endpoint = {
      subdomain = "monitor";
      inherit port;
    };

    nixos = {config, ...}: {
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
  };
}
