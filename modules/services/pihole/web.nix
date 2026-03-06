{config, ...}: {
  services.pihole-web = {
    enable = true;
    ports = [config.my.endpoints.pihole.port];
  };
}
