{self, ...}: {
  flake.nixosModules = {
    srv-enclosed = {config, ...}: let
      inherit (self.lib) endpoint;
      port = 8788;
    in {
      imports = [
        self.nixosModules.enclosed-secrets
        (endpoint {
          subdomain = "share";
          tunnel = true;
          inherit port;
        })
      ];

      virtualisation.oci-containers.containers.enclosed = {
        image = "corentinth/enclosed:latest";
        ports = ["${toString port}:8787"];
        environment.PUBLIC_IS_AUTHENTICATION_REQUIRED = "true";
        environmentFiles = [config.sops.templates."enclosed.env".path];
        volumes = ["/data/enclosed:/app/.data"];
      };

      systemd.tmpfiles.rules = ["d /data/enclosed 0775 1000 data -"];
    };

    enclosed-secrets = {config, ...}: {
      sops.secrets."enclosed/jwt-secret" = {};
      sops.secrets."enclosed/auth-users" = {};
      sops.templates."enclosed.env" = {
        content = ''
          AUTHENTICATION_JWT_SECRET=${config.sops.placeholder."enclosed/jwt-secret"}
          AUTHENTICATION_USERS=${config.sops.placeholder."enclosed/auth-users"}
        '';
      };
    };
  };
}
