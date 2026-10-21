# conf-nixos' core, without the terminal
{
  den.aspects.apps.core.nixos = {
    pkgs,
    lib,
    ...
  }: {
    environment.systemPackages = [
      pkgs.git
      pkgs.systemctl-tui

      pkgs.nix-your-shell

      pkgs.uutils-coreutils-noprefix
      pkgs.killall
      pkgs.lsd
      pkgs.xcp
      pkgs.rip2
      pkgs.bat
      pkgs.fd
      pkgs.ripgrep
      pkgs.ripgrep-all
      pkgs.ouch
      pkgs.unzip
      pkgs.eva
      pkgs.hyperfine
      pkgs.dust
    ];

    programs.zoxide.enable = true;

    programs.fish.interactiveShellInit = ''
      set fish_greeting
      nix-your-shell fish | source

      function mkcd
        mkdir -p $argv[1]; and cd $argv[1]
      end

      # builtin: keeps temp dirs out of zoxide
      function mktempd
        builtin cd (mktemp -d)
      end

      # ctrl-z back into the suspended job, alt-z for zoxide's picker
      bind ctrl-z 'fg 2>/dev/null; commandline -f repaint'
      bind alt-z 'zi; commandline -f repaint'
    '';

    programs.fish.shellAliases = {
      ls = "lsd -F --total-size --group-directories-first --hyperlink auto --git --extensionsort --classify";
      l = "ls -1";
      ll = "ls -lA";
      lr = "ll --recursive";
      tree = "ls --tree";

      top = "btop";
      bottom = "btop";

      find = "fd --no-ignore";
      findh = "find --hidden";
      findg = "fd";
      findhg = "findg --hidden";

      calculator = "eva";
      calc = "eva";

      wtime = "hyperfine --runs 1 --warmup 3 --";
      bench = "hyperfine --runs 5 --";
      wbench = "hyperfine --runs 5 --warmup 3 --";

      grep = "rg";
      grepa = "rga";

      cat = "bat --theme=ansi"; # inherit terminal theme
      cp = "xcp";
      rm = "rip";
      cd = "z";
      fz = "tv";
      du = "dust";
    };

    programs.fish.shellAbbrs = let
      cd_abbr_count = 7;
    in
      {
        compress = "ouch compress";
        decompress = "ouch decompress";

        sc = "sudo systemctl";
        scu = "systemctl --user";
        jf = "journalctl -fu";
        jfu = "journalctl --user -fu";
      }
      // lib.listToAttrs (
        map (n: {
          name = lib.concatStrings (lib.genList (_: ".") n); # n dots
          value = "cd ${lib.concatStringsSep "/" (lib.genList (_: "..") (n - 1))}"; # prev_dir based on n
        }) (lib.range 2 (cd_abbr_count + 1))
      );
  };
}
