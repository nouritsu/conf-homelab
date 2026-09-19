{
  inputs,
  den,
  ...
}: {
  den.aspects.homelab = {
    includes =
      [den.batteries.hostname]
      ++ (with den.aspects; [
        server

        # hardware
        graphics
        storage
        homelab.disko

        # services
        services.openrgb
        services.beszel
        services.copyparty
        services.bookshelf
        services.bazarr
        services.scrutiny
        services.paperless
        services.homeassistant
        services.prowlarr
        services.tailscale
        services.radarr
        services.pihole
        services.jellyfin
        services.enclosed
        services.sonarr
        services.documenso
        services.syncthing
        services.qbittorrent
        services.mousehole
        services.sabnzbd
      ]);

    nixos = {pkgs, ...}: {
      imports = let
        rpinm = inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5;
      in
        with rpinm; [
          base
          page-size-16k
          display-vc4
          bluetooth
        ];

      networking.domain = den.lib.homelab.base-domain;

      boot.loader.raspberry-pi.bootloader = "kernel";
      environment.systemPackages = [pkgs.raspberrypi-eeprom];

      # ================================================================ #
      # =                         DO NOT TOUCH                         = #
      # ================================================================ #
      system.stateVersion = "25.11";
    };
  };
}
