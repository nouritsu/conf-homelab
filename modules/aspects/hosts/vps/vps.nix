{den, ...}: {
  den.aspects.vps = {
    includes = with den.aspects; [
      cloud
      vps.disko

      caddy
      rathole.server
      beszel-agent

      # services
      edge.www
      edge.hire-me
      edge.headscale
      edge.headplane
    ];

    nixos = {
      # ================================================================ #
      # =                         DO NOT TOUCH                         = #
      # ================================================================ #
      system.stateVersion = "23.11";

      sops.defaultSopsFile = ./secrets.yaml;
      sops.age.keyFile = "/root/sops.txt";

      networking.domain = den.lib.homelab.base-domain;
    };
  };
}
