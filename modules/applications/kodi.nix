{
  flake.nixosModules.app-kodi = {
    pkgs,
    lib,
    ...
  }: let
    kodiWithJellyfin = pkgs.kodi-gbm.withPackages (p:
      with p; [
        jellyfin
      ]);

    kodi = lib.getExe' kodiWithJellyfin "kodi-standalone";
  in {
    users.users.kodi = {
      isNormalUser = true;
      extraGroups = ["video" "audio" "input" "render" "seat" "pipewire"];
    };

    services.cage = {
      enable = true;
      user = "kodi";
      program = kodi;
      environment = {
        WLR_NO_HARDWARE_CURSORS = "1";
        LIBSEAT_BACKEND = "seatd";
        XCURSOR_SIZE = "0";
      };
    };

    # fix kodi service being marked as failed after crash
    systemd.services.cage-tty1.serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = 2;
    };

    services.seatd.enable = true;

    # HDMI CEC
    environment.systemPackages = [pkgs.libcec];

    services.udev.extraRules = ''
      KERNEL=="vchiq", GROUP="video", MODE="0660"
      KERNEL=="cec[0-9]*", GROUP="video", MODE="0660"
    '';

    nixpkgs.overlays = [
      (final: prev: {
        libcec = prev.libcec.override {
          withLibraspberrypi = true;
        };
      })
    ];
  };
}
