{
  # conf-nixos' nix.abbrs without nh os and conf: the flake isn't on the homelab
  den.aspects.nix.abbrs.nixos = {
    programs.fish.shellAbbrs = {
      nhca = "nh clean all";
      nhs = "nh search";

      nd = "nix develop";
      nb = "nix build";
      nfu = "nix flake update";
      nfs = "nix flake show";
    };

    programs.fish.interactiveShellInit = ''
      abbr -a nr --set-cursor 'nix run nixpkgs#%'
    '';
  };
}
