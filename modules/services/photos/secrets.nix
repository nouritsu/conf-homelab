{config, ...}: {
  sops.templates."immich.env" = {
    content = ''
      DB_PASSWORD=${config.sops.placeholder."postgres-password"}
      DB_HOSTNAME=immich-db
      DB_PORT=5434
      DB_USERNAME=immich
      DB_DATABASE_NAME=immich
      REDIS_HOSTNAME=immich-redis
      REDIS_PORT=6379
    '';
  };
}
