let
  TWELVE_HOURS_SECONDS = 43200;
in {
  services.pihole-ftl.settings = {
    dns = {
      bind_hosts = ["192.168.178.128" "127.0.0.1"];
      interface = "end0";

      upstreams = [
        "1.1.1.1"
        "1.0.0.1"
      ];

      domainNeeded = true;
      expandHosts = true;

      hosts = [
        "192.168.178.1   gateway"
        "192.168.178.128   pihole"
      ];
    };

    dhcp.active = false;

    webserver = {
      api = {
        # TODO: add passwords
      };
      session.timeout = TWELVE_HOURS_SECONDS;
    };

    ntp = {
      ipv4.active = false;
      ipv6.active = false;
      sync.active = false;
    };
  };
}
