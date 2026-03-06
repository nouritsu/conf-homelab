{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.nh
  ];

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
}
