{
  flake.nixosModules.audio = {pkgs, ...}: {
    environment.systemPackages = [pkgs.pulseaudio];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      systemWide = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    services.pulseaudio.enable = false;
  };
}
