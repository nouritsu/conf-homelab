{config, ...}: {
  sops.secrets."rathole-token" = {};
  sops.secrets."rathole-remote-addr" = {};
  sops.templates."rathole-credentials.toml" = {
    content =
      /*
      toml
      */
      ''
        [client]
        remote_addr = "${config.sops.placeholder."rathole-remote-addr"}"

        [client.services.sign]
        token = "${config.sops.placeholder."rathole-token"}"

        [client.services.share]
        token = "${config.sops.placeholder."rathole-token"}"
      '';
  };

  services.rathole = {
    enable = true;
    role = "client";
    credentialsFile = config.sops.templates."rathole-credentials.toml".path;
    settings = {
      client = {
        services.sign = {
          local_addr = "127.0.0.1:3000";
        };
        services.share = {
          local_addr = "127.0.0.1:8788";
        };
      };
    };
  };
}
