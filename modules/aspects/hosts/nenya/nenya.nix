{den, ...}: {
  den.aspects.nenya = {
    includes = with den.aspects; [
      cloud
      nenya.disko

      virtualization.podman
      containers

      # services
      games.valheim
      games.minecraft
      games.hkmp
      games.satisfactory
    ];

    nixos = {
      # ================================================================ #
      # =                         DO NOT TOUCH                         = #
      # ================================================================ #
      system.stateVersion = "25.11";

      sops.defaultSopsFile = ./secrets.yaml;
      sops.age.keyFile = "/root/keys.txt";

      networking.domain = den.lib.homelab.base-domain;

      boot.loader.grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
  };
}
