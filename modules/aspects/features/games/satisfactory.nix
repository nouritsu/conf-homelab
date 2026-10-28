{
  den.aspects.games.satisfactory.nixos = {pkgs, ...}: {
    virtualisation.oci-containers.containers.satisfactory = {
      image = "wolveix/satisfactory-server:latest@sha256:ac252dba41653eb21c6feed94b577f98fa152f5792b1aeff2ce11fe364355137";

      ports = [
        "7777:7777/tcp"
        "7777:7777/udp"
        "8888:8888/tcp"
      ];

      volumes = [
        "/data/satisfactory:/config"
      ];

      environment = {
        PUID = "1000";
        PGID = "1000";
        STEAMBETA = "false";
      };

      extraOptions = ["--memory-reservation=6G" "--memory=12G"];
    };

    # a restart drops everyone mid-session
    systemd.timers.restart-container-satisfactory.enable = false;

    systemd.tmpfiles.rules = [
      "d /data/satisfactory 0755 1000 1000 - -"
    ];

    networking.firewall.allowedTCPPorts = [7777 8888];
    networking.firewall.allowedUDPPorts = [7777];

    environment.systemPackages = [pkgs.ficsit-cli];
  };
}
