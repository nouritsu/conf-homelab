{
  flake.nixosModules.app-fish = {pkgs, ...}: {
    users.defaultUserShell = pkgs.fish;

    environment.systemPackages = with pkgs.fishPlugins; [
      autopair
      humantime-fish
      colored-man-pages
    ];

    programs.fish = {
      enable = true;

      interactiveShellInit =
        /*
        fish
        */
        ''
          set fish_greeting
        '';
    };
  };
}
