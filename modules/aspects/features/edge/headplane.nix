let
  # off 3000: rathole binds the homelab's documenso there
  port = 3030;
in {
  # headscale's web ui; reads headscale's own settings, so it lives beside it
  den.aspects.edge.headplane = {
    endpoint = {
      subdomain = "mesh";
      public = true;
      inherit port;
      extraConfig = ''
        basicauth {
          admin $2a$14$njq9OkElD8UtrqvenYTr0ejoDrR.lVPjx65KrKqGiHaWDFefoPZPq
        }
      '';
    };

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: let
      fmt = pkgs.formats.yaml {};
      headscale-config = fmt.generate "headscale.yml" (lib.recursiveUpdate config.services.headscale.settings {
        tls_cert_path = "/dev/null";
        tls_key_path = "/dev/null";
        policy.path = "/dev/null";
      });
    in {
      sops.secrets."headplane/cookie-secret".owner = "headscale";

      # no agent: since 0.7 it needs a headscale api key, which the pre-auth key in agent-authkey is not
      services.headplane = {
        enable = true;
        settings = {
          server = {
            host = "127.0.0.1";
            inherit port;
            cookie_secret_path = config.sops.secrets."headplane/cookie-secret".path;
          };
          headscale = {
            url = "http://127.0.0.1:${toString config.services.headscale.port}";
            config_path = "${headscale-config}";
          };
        };
      };
    };
  };
}
