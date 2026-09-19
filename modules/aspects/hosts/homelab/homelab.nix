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
        homelab-disko

        # services
        srv-openrgb
        srv-beszel
        srv-copyparty
        srv-bookshelf
        srv-bazarr
        srv-scrutiny
        srv-paperless
        srv-homeassistant
        srv-prowlarr
        srv-tailscale
        srv-radarr
        srv-pihole
        srv-jellyfin
        srv-enclosed
        srv-sonarr
        srv-documenso
        srv-syncthing
        srv-qbittorrent
        srv-mousehole
        srv-sabnzbd
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
