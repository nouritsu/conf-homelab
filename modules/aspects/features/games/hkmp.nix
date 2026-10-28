let
  port = 2222;
in {
  # hollow knight multiplayer
  den.aspects.games.hkmp.nixos = {
    virtualisation.oci-containers.containers.hkmp = {
      image = "maximalmax90/hkmpserver:latest@sha256:162c4da5afefe9e9401da9608dbda5782555216721e4e9ad49e8c0d1a9ec097c";
      ports = ["${toString port}:${toString port}/udp"];
      environment.PORT = toString port;
      volumes = ["/data/hkmp:/HKMP"];
    };

    systemd.tmpfiles.rules = [
      "d /data/hkmp 0755 root root - -"
    ];

    networking.firewall.allowedUDPPorts = [port];
  };
}
