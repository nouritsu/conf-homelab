{
  imports = [
    # boot
    boot/eeprom.nix
    boot/rpiboot.nix

    # core
    core/base.nix
    core/paging.nix

    # graphics
    graphics/graphics.nix

    # i18n
    i18n/locale.nix
    i18n/timezone.nix

    # network
    network/bluetooth.nix
    network/networkmanager.nix
    network/hostname.nix
    network/ssh.nix

    # nix
    nix/cache.nix
    nix/nh.nix
    nix/misc.nix
    nix/overlays.nix

    # peripherals
    peripherals/display.nix
    peripherals/openrgb.nix

    # security
    security/firewall.nix

    # sound
    sound/sound.nix

    # storage
    storage/nvme.nix
    storage/xfs.nix
    storage/hdd.nix
    storage/usb-ssd.nix

    # user
    user/aneesh.nix

    # virtualisation
    virtualisation/podman.nix
  ];
}
