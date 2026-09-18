{
  inputs,
  self,
  ...
}: {
  den.aspects.homelab.nixos = {
    imports = with self.nixosModules; [
      homelab-system
      homelab-disko
      secrets

      # system
      graphics
      audio
      locale
      auto-tz
      network
      storage
      fs-xfs
      fs-btrfs
      user-aneesh
      virt-podman
      containers

      # ssh
      ssh-base
      ssh-from-pc
      ssh-from-phone

      # nix
      nix-base
      nix-cache
      nixpkgs-unfree

      # applications
      app-core
      app-fish
      app-nh
      # app-kodi

      # infrastructure
      caddy
      gluetun
      rathole
      postfix

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
    ];
  };

  flake.nixosModules = {
    homelab-system = {pkgs, ...}: {
      imports = let
        rpinm = inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5;
      in
        with rpinm; [
          base
          page-size-16k
          display-vc4
          bluetooth
        ];

      networking.hostName = "homelab";
      networking.domain = self.lib.base-domain;

      boot.loader.raspberry-pi.bootloader = "kernel";
      environment.systemPackages = [pkgs.raspberrypi-eeprom];

      # ================================================================ #
      # =                         DO NOT TOUCH                         = #
      # ================================================================ #
      system.stateVersion = "25.11";
    };
  };
}
