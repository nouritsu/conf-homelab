{den, ...}: {
  # consumes the tunnelled subset of the `endpoint` quirk
  den.aspects.rathole.nixos = {
    endpoint,
    config,
    lib,
    ...
  }: let
    role = config.services.rathole.role;

    addr-key =
      if role == "client"
      then "local_addr"
      else "bind_addr";

    tunnelled =
      lib.sort (a: b: a.subdomain < b.subdomain)
      (lib.filter (e: e.tunnel or false) endpoint);
  in {
    sops.secrets."rathole/token" = {};
    sops.secrets."rathole/remote-addr" = {};

    services.rathole = {
      enable = true;
      role = "client";
      credentialsFile = config.sops.templates."rathole-credentials.toml".path;
    };

    services.rathole.settings.${role}.services = lib.listToAttrs (map (e:
      lib.nameValuePair e.subdomain {
        ${addr-key} = "127.0.0.1:${toString e.port}";
      })
    tunnelled);

    sops.templates."rathole-credentials.toml".content =
      ''
        [${role}]
        remote_addr = "${config.sops.placeholder."rathole/remote-addr"}"
      ''
      + lib.concatMapStrings (e: ''

        [${role}.services.${e.subdomain}]
        token = "${config.sops.placeholder."rathole/token"}"
      '')
      tunnelled;
  };
}
