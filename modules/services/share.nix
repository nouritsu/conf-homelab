{self, ...}: {
  flake.nixosModules = {
    srv-enclosed = {config, ...}: let
      port = "8788";
    in {
      imports = [self.nixosModules.enclosed-secrets];
      my.containers.enclosed = {
        enable = true;
        image = {
          provider = "official";
          owner = "corentinth";
        };
        ports = ["${port}:8787"];
        env.PUBLIC_IS_AUTHENTICATION_REQUIRED = "true";
        envFile = [config.sops.templates."enclosed.env".path];
        vols = ["/data/enclosed:/app/.data"];
      };
      systemd.tmpfiles.rules = ["d /data/enclosed 0775 1000 data -"];
    };

    enclosed-secrets = {config, ...}: {
      sops.secrets."enclosed-jwt-secret" = {};
      sops.secrets."enclosed-auth-users" = {};
      sops.templates."enclosed.env" = {
        content = ''
          AUTHENTICATION_JWT_SECRET=${config.sops.placeholder."enclosed-jwt-secret"}
          AUTHENTICATION_USERS=${config.sops.placeholder."enclosed-auth-users"}
        '';
      };
    };
  };
}
