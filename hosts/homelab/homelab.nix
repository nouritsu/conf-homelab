{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.homelab = inputs.nixos-raspberrypi.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
      inherit (inputs) nixos-raspberrypi;
    };

    modules = with self.nixosModules; [
      homelab-system
      homelab-disko
      secrets
      opts-endpoints
      opts-containers

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

      # infrastructure
      caddy
      gluetun
      rathole
      postfix

      # services
      srv-openrgb
      srv-beszel
      srv-copyparty
      srv-grocy
      srv-bookshelf
      srv-bazarr
      srv-cook-cli
      srv-scrutiny
      srv-paperless
      srv-aria2
      srv-homeassistant
      srv-prowlarr
      srv-tailscale
      srv-roundcube
      srv-jellyseerr
      srv-uptime-kuma
      srv-radarr
      srv-immich
      srv-pihole
      srv-jellyfin
      srv-enclosed
      srv-sonarr
      srv-documenso
      srv-syncthing
      srv-qbittorrent
      srv-myanonymouse-seedboxapi
      srv-sabnzbd
      srv-vaultwarden
      # srv-wg-easy
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
      networking.domain = "nouritsu.com";

      boot.loader.raspberryPi.bootloader = "kernel";
      environment.systemPackages = [pkgs.raspberrypi-eeprom];

      # ================================================================ #
      # =                         DO NOT TOUCH                         = #
      # ================================================================ #
      system.stateVersion = "25.11";
    };
  };
}
