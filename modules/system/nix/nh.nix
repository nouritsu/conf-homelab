{config, ...}: {
  programs.nh = {
    enable = true;
    flake = "/home/${config.my.user.alias}/.config/nixos";
  };
}
