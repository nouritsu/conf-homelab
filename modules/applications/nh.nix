{
  flake.nixosModules.app-nh = {...}: {
    programs.nh = {
      enable = true;
      flake = "/home/aneesh/.config/nixos";
    };

    programs.fish = {
      shellAbbrs = {
        nhrb = "nh os boot";
        nhrs = "nh os switch";
        nhrt = "nh os test";
        nhca = "nh clean all";
        nhs = "nh search";
      };

      shellAliases = {
        conf = "$EDITOR $NH_FLAKE";
      };
    };
  };
}
