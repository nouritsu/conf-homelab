{self, ...}: {
  flake.nixosModules = {
    srv-documenso = {config, ...}: let
      inherit (self.lib) endpoint fqdn;
      domain = fqdn "sign";
      port = 3000;

      smtp-host = "smtp.hostinger.com";
      smtp-port = 465;
    in {
      imports = [
        self.nixosModules.documenso-secrets
        self.nixosModules.documenso-db
        (endpoint {
          subdomain = "sign";
          tunnel = true;
          inherit port;
        })
      ];

      virtualisation.oci-containers.containers.documenso = {
        image = "documenso/documenso:latest";
        dependsOn = ["documenso-db"];
        ports = ["${toString port}:3000"];
        environment = {
          NEXT_PRIVATE_SMTP_HOST = smtp-host;
          NEXT_PRIVATE_SMTP_PORT = toString smtp-port;
          NEXT_PRIVATE_SMTP_SECURE = "true";
          PORT = toString port;
          NEXTAUTH_URL = "https://${domain}";
          NEXT_PUBLIC_WEBAPP_URL = "https://${domain}";
          NEXT_PRIVATE_INTERNAL_WEBAPP_URL = "http://localhost:${toString port}";
          NEXT_PRIVATE_SMTP_TRANSPORT = "smtp-auth";
          NEXT_PRIVATE_SMTP_FROM_NAME = "Documenso";
          NEXT_PRIVATE_SIGNING_LOCAL_FILE_PATH = "/opt/documenso/cert.p12";
          NEXT_PUBLIC_DISABLE_SIGNUP = "true";
          DOCUMENSO_DISABLE_TELEMETRY = "true";
        };
        environmentFiles = [config.sops.templates."documenso.env".path];
        volumes = ["${config.sops.secrets."documenso-cert".path}:/opt/documenso/cert.p12:ro"];
        extraOptions = ["--add-host=documenso-db:host-gateway"];
      };
    };

    documenso-secrets = {config, ...}: {
      sops.secrets."sign/nextauth-secret" = {};
      sops.secrets."sign/next-key" = {};
      sops.secrets."sign/next-secondary-key" = {};
      sops.secrets."sign/next-signing-pass" = {};
      sops.secrets."mail/home-password" = {};
      sops.secrets."mail/home-mail" = {};
      sops.secrets."sign/sign-mail" = {};
      sops.templates."documenso.env" = {
        content = ''
          NEXTAUTH_SECRET=${config.sops.placeholder."sign/nextauth-secret"}
          NEXT_PRIVATE_ENCRYPTION_KEY=${config.sops.placeholder."sign/next-key"}
          NEXT_PRIVATE_ENCRYPTION_SECONDARY_KEY=${config.sops.placeholder."sign/next-secondary-key"}
          NEXT_PRIVATE_SIGNING_PASSPHRASE=${config.sops.placeholder."sign/next-signing-pass"}
          NEXT_PRIVATE_SMTP_USERNAME=${config.sops.placeholder."mail/home-mail"}
          NEXT_PRIVATE_SMTP_FROM_ADDRESS=${config.sops.placeholder."sign/sign-mail"}
          NEXT_PRIVATE_SMTP_PASSWORD=${config.sops.placeholder."mail/home-password"}
          NEXT_PRIVATE_DATABASE_URL=postgresql://documenso:${config.sops.placeholder."sign/postgres-password"}@documenso-db:5433/documenso
          NEXT_PRIVATE_DIRECT_DATABASE_URL=postgresql://documenso:${config.sops.placeholder."sign/postgres-password"}@documenso-db:5433/documenso
        '';
      };
    };

    documenso-db = {config, ...}: {
      imports = [self.nixosModules.documenso-db-secrets];

      virtualisation.oci-containers.containers.documenso-db = {
        image = "postgres:15";
        environment = {
          POSTGRES_USER = "documenso";
          POSTGRES_DB = "documenso";
        };
        environmentFiles = [config.sops.templates."documenso-postgres.env".path];
        volumes = ["documenso-db:/var/lib/postgresql/data"];
        ports = ["5433:5432"];
        extraOptions = [
          "--health-cmd=pg_isready -U documenso"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };

      systemd.timers.restart-container-documenso-db.enable = false; # database
    };

    documenso-db-secrets = {config, ...}: {
      sops.secrets."sign/postgres-password" = {};
      sops.templates."documenso-postgres.env" = {
        content = ''
          POSTGRES_PASSWORD=${config.sops.placeholder."sign/postgres-password"}
        '';
      };
    };
  };
}
