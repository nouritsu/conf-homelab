{
  den.aspects.rathole.nixos = {
    config,
    lib,
    ...
  }: {
    sops.secrets."rathole/token" = {};
    sops.secrets."rathole/remote-addr" = {};

    services.rathole = {
      enable = true;
      role = "client";
      credentialsFile = config.sops.templates."rathole-credentials.toml".path;
    };

    # each endpoint appends its own [client.services.<name>] block with mkAfter
    sops.templates."rathole-credentials.toml".content = lib.mkBefore ''
      [client]
      remote_addr = "${config.sops.placeholder."rathole/remote-addr"}"
    '';
  };
}
