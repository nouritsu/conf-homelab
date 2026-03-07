{self, ...}: {
  flake.nixosModules = {
    srv-documenso = {config, ...}: let
      smtp-host = "smtp.hostinger.com";
      smtp-port = 465;
    in {
      imports = [
        self.nixosModules.documenso-secrets
        self.nixosModules.documenso-db
      ];
      my.containers.documenso = {
        enable = true;
        image.provider = "official";
        ports = ["3000:3000"];
        env = {
          NEXT_PRIVATE_SMTP_HOST = smtp-host;
          NEXT_PRIVATE_SMTP_PORT = toString smtp-port;
          NEXT_PRIVATE_SMTP_USERNAME = "home@nouritsu.com";
          NEXT_PRIVATE_SMTP_FROM_ADDRESS = "sign@nouritsu.com";
          NEXT_PRIVATE_SMTP_SECURE = "true";
          PORT = "3000";
          NEXTAUTH_URL = "https://sign.nouritsu.com";
          NEXT_PUBLIC_WEBAPP_URL = "https://sign.nouritsu.com";
          NEXT_PRIVATE_INTERNAL_WEBAPP_URL = "http://localhost:3000";
          NEXT_PRIVATE_SMTP_TRANSPORT = "smtp-auth";
          NEXT_PRIVATE_SMTP_FROM_NAME = "Documenso";
          NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH = "/opt/documenso/cert.p12";
          NEXT_PUBLIC_DISABLE_SIGNUP = "true";
          DOCUMENSO_DISABLE_TELEMETRY = "true";
        };
        envFile = [config.sops.templates."documenso.env".path];
        vols = ["${config.sops.secrets."documenso-cert".path}:/opt/documenso/cert.p12:ro"];
        extra-options = ["--add-host=documenso-db:host-gateway"];
      };
      virtualisation.oci-containers.containers.documenso.dependsOn = ["documenso-db"];
    };

    documenso-secrets = {config, ...}: {
      sops.secrets."nextauth-secret" = {};
      sops.secrets."next-key" = {};
      sops.secrets."next-secondary-key" = {};
      sops.secrets."next-signing-pass" = {};
      sops.templates."documenso.env" = {
        content = ''
          NEXTAUTH_SECRET=${config.sops.placeholder."nextauth-secret"}
          NEXT_PRIVATE_ENCRYPTION_KEY=${config.sops.placeholder."next-key"}
          NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=${config.sops.placeholder."next-secondary-key"}
          NEXT_PRIVATE_SIGNING_PASSPHRASE=${config.sops.placeholder."next-signing-pass"}
          NEXT_PRIVATE_SMTP_PASSWORD=${config.sops.placeholder."home-mail-password"}
          NEXT_PRIVATE_DATABASE_URL=postgresql://documenso:${config.sops.placeholder."postgres-password"}@documenso-db:5433/documenso
          NEXT_PRIVATE_DIRECT_DATABASE_URL=postgresql://documenso:${config.sops.placeholder."postgres-password"}@documenso-db:5433/documenso
        '';
      };
    };

    documenso-db = {config, ...}: {
      imports = [self.nixosModules.documenso-db-secrets];
      my.containers.documenso-db = {
        enable = true;
        image.url = "postgres:15";
        env = {
          POSTGRES_USER = "documenso";
          POSTGRES_DB = "documenso";
        };
        envFile = [config.sops.templates."documenso-postgres.env".path];
        vols = ["documenso-db:/var/lib/postgresql/data"];
        ports = ["5433:5432"];
        extra-options = [
          "--health-cmd=pg_isready -U documenso"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };
    };

    documenso-db-secrets = {config, ...}: {
      sops.secrets."postgres-password" = {};
      sops.templates."documenso-postgres.env" = {
        content = ''
          POSTGRES_PASSWORD=${config.sops.placeholder."postgres-password"}
        '';
      };
    };
  };
}
