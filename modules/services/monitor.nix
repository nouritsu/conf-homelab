{self, ...}: {
  flake.nixosModules = {
    srv-beszel = {config, ...}: {
      imports = [
        self.nixosModules.beszel-secrets
      ];

      my.endpoints.beszel = {
        enable = true;
        tlsInternal = true;
        port = 8090;
        subdomain = "monitor";
      };

      services.beszel = {
        hub.enable = true;

        agent.enable = true;
        agent.environmentFile = config.sops.templates."beszel.env".path;
      };
    };

    beszel-secrets = {config, ...}: {
      sops.secrets."beszel-token" = {};
      sops.secrets."beszel-key" = {};

      sops.templates."beszel.env" = {
        content = ''
          HUB_URL="http://localhost:8090"
          KEY="${config.sops.placeholder."beszel-key"}"
          TOKEN="${config.sops.placeholder."beszel-token"}"
        '';
      };
    };
  };
}
