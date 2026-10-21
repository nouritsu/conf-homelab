# conf-nixos' helix, with nixpkgs' helix instead of the wrapped one
{
  den.aspects.apps.helix.nixos = {pkgs, ...}: {
    environment.systemPackages = [pkgs.helix];

    programs.nano.enable = false;

    environment.variables.EDITOR = "hx";

    # open every file rg matches
    programs.fish.interactiveShellInit = ''
      function hxrg
        hx (rg -l $argv)
      end
    '';

    programs.fish.shellAliases = let
      e = "hx";
    in {
      helix = e;
      vi = e;
      vim = e;
      nvim = e;
    };
  };
}
