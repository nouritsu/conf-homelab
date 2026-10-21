{
  den.aspects.nix.gc.nixos = {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep 5 --keep-since 7d";
    };
  };
}
