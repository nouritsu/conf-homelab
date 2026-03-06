{
  my.endpoints.uptime-kuma = {
    port = 4000;
    subdomain = "monitor";
  };

  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "4000";
    };
  };
}
