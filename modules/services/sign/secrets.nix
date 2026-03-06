{config, ...}: {
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
}
