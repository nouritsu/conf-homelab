{den, ...}: let
  inherit (den.lib.policy) pipe;
in {
  # a client tunnels its own public `endpoint`s; a server publishes its `tunnel` quirk
  den.aspects.rathole.nixos = {
    endpoint,
    tunnel,
    config,
    lib,
    ...
  }: let
    role = config.services.rathole.role;
    client = role == "client";

    addr-key =
      if client
      then "local_addr"
      else "bind_addr";

    tunnelled =
      lib.sort (a: b: a.subdomain < b.subdomain)
      (
        if client
        then lib.filter (e: e.public or false) endpoint
        else tunnel
      );
  in {
    sops.secrets."rathole/token".sopsFile = den.lib.homelab.shared-secrets;
    sops.secrets."rathole/remote-addr" = lib.mkIf client {};

    services.rathole = {
      enable = true;
      role = lib.mkDefault "client";
      credentialsFile = config.sops.templates."rathole-credentials.toml".path;
    };

    # both ends use the service's own port; caddy on the server proxies to it
    services.rathole.settings.${role}.services = lib.listToAttrs (map (e:
      lib.nameValuePair e.subdomain {
        ${addr-key} = "127.0.0.1:${toString e.port}";
      })
    tunnelled);

    sops.templates."rathole-credentials.toml".content =
      lib.optionalString client ''
        [${role}]
        remote_addr = "${config.sops.placeholder."rathole/remote-addr"}"
      ''
      + lib.concatMapStrings (e: ''

        [${role}.services.${e.subdomain}]
        token = "${config.sops.placeholder."rathole/token"}"
      '')
      tunnelled;

    assertions = let
      ports = map (e: e.port) (lib.filter (e: e ? port) endpoint);
      clashes = lib.filter (e: lib.elem e.port ports) tunnel;
    in [
      {
        assertion = clashes == [];
        message = "rathole: tunnelled ports already used by an endpoint here (${lib.concatMapStringsSep ", " (e: "${e.subdomain}:${toString e.port}") clashes})";
      }
    ];
  };

  # every host naming this one in tunnels-via has its public endpoints collected here
  den.policies.collect-tunnels = {host, ...}: let
    server = host.name;
  in [
    (pipe.from "endpoint" [
      # stages run in order: drop this host's own endpoints, then collect
      (pipe.filter (_: false))
      (pipe.collectAll ({host, ...}: host.tunnels-via == server))
      (pipe.filter (e: e.public or false))
      (pipe.as "tunnel")
    ])
  ];

  den.aspects.rathole.server = {
    # a sub-aspect does not bring its parent along
    includes = [
      den.aspects.rathole
      den.policies.collect-tunnels
    ];

    nixos = {
      services.rathole.role = "server";
      services.rathole.settings.server.bind_addr = "0.0.0.0:2333";
      networking.firewall.allowedTCPPorts = [2333];
    };
  };
}
