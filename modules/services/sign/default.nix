{config, ...}: let
  smtp-host = "smtp.hostinger.com";
  smtp-port = 465;
in {
  imports = [
    ./postgres.nix
    ./secrets.nix
  ];

  # now handled by rathole
  # my.endpoints.documenso = {
  #   port = 3000;
  #   subdomain = "sign";
  # };

  my.containers.documenso = {
    enable = true;

    image = {
      provider = "official";
    };

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

    envFile = [
      config.sops.templates."documenso.env".path
    ];

    vols = [
      "${config.sops.secrets."documenso-cert".path}:/opt/documenso/cert.p12:ro"
    ];

    extra-options = [
      "--add-host=documenso-db:host-gateway"
    ];
  };

  # Override dependsOn since the containers API doesn't support custom dependencies
  virtualisation.oci-containers.containers.documenso.dependsOn = ["documenso-db"];
}
