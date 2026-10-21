{
  den.aspects.services.enclosed = let
    port = 8788;
  in {
    endpoint = {
      subdomain = "share";
      tunnel = true;
      inherit port;
    };

    nixos = {config, ...}: {
      sops.secrets."enclosed/jwt-secret" = {};
      sops.secrets."enclosed/auth-users" = {};
      sops.templates."enclosed.env" = {
        content = ''
          AUTHENTICATION_JWT_SECRET=${config.sops.placeholder."enclosed/jwt-secret"}
          AUTHENTICATION_USERS=${config.sops.placeholder."enclosed/auth-users"}
        '';
      };

      virtualisation.oci-containers.containers.enclosed = {
        image = "corentinth/enclosed:latest@sha256:d1e78c34ae7027c0c7b7a9ba67f352520049b9f260560fb8a0b3b1c55488cdc8";
        ports = ["${toString port}:8787"];
        environment.PUBLIC_IS_AUTHENTICATION_REQUIRED = "true";
        environmentFiles = [config.sops.templates."enclosed.env".path];
        volumes = ["/data/enclosed:/app/.data"];
      };

      systemd.tmpfiles.rules = ["d /data/enclosed 0775 1000 data -"];
    };
  };
}
