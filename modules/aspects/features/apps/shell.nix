# conf-nixos' shell, with btop, tealdeer and television wrapped here from the host's pkgs
{inputs, ...}: let
  inherit (inputs) wrappers nix-colors;
  inherit (nix-colors.colorSchemes.catppuccin-mocha) palette;
  inherit (nix-colors.lib.conversions) hexToRGB;

  rgb = slot: let
    c = hexToRGB palette.${slot};
  in {
    rgb = {
      r = builtins.elemAt c 0;
      g = builtins.elemAt c 1;
      b = builtins.elemAt c 2;
    };
  };
in {
  den.aspects.apps.shell.nixos = {
    pkgs,
    lib,
    ...
  }: let
    # mocha highlights in blue; swap in mauve
    btop-theme = pkgs.runCommand "catppuccin_mocha_mauve.theme" {} ''
      sed \
        -e 's/^theme\[hi_fg\]=.*/theme[hi_fg]="#${palette.base0E}"/' \
        -e 's/^theme\[selected_fg\]=.*/theme[selected_fg]="#${palette.base0E}"/' \
        ${inputs.catppuccin-btop}/themes/catppuccin_mocha.theme > $out
    '';

    btop = wrappers.wrappers.btop.wrap [
      {
        inherit pkgs;
        package = pkgs.btop;
      }
      {
        themes.catppuccin_mocha_mauve = btop-theme;

        settings = {
          color_theme = "catppuccin_mocha_mauve.theme";
          theme_background = false;
          proc_tree = true;
          proc_gradient = false;
          update_ms = 1000;

          # gpu0 is dropped when there's no gpu
          shown_boxes = "cpu mem net proc gpu0";

          # config is in the store, nowhere to save
          save_config_on_exit = false;
        };
      }
    ];

    tealdeer = wrappers.wrappers.tealdeer.wrap [
      {
        inherit pkgs;
        package = pkgs.tealdeer;
      }
      {
        settings = {
          updates = {
            auto_update = true;
            auto_update_interval_hours = 24;
          };

          # no catppuccin port; mauve for every highlight
          style = {
            description.foreground = rgb "base05";
            example_text.foreground = rgb "base0B";
            example_code.foreground = rgb "base05";
            command_name = {
              foreground = rgb "base0E";
              bold = true;
            };
            example_variable = {
              foreground = rgb "base0E";
              underline = true;
            };
          };
        };
      }
    ];

    television = wrappers.wrappers.television.wrap [
      {
        inherit pkgs;
        package = pkgs.television;
      }
      {
        settings = {
          # cable channels are written for sh
          shell = "bash";

          # port as overrides; tv only reads theme files from its config dir
          ui.theme = "catppuccin";
          ui.theme_overrides = lib.importTOML "${inputs.catppuccin-television}/themes/catppuccin-mocha-mauve.toml";

          # replaces tv's default triggers
          shell_integration = {
            fallback_channel = "files";
            channel_triggers = {
              alias = ["alias" "funced"];
              dirs = ["cd" "z" "ls" "l" "ll" "lr" "tree" "rmdir" "pushd"];
              files = ["cat" "bat" "hx" "less" "head" "tail" "cp" "xcp" "mv" "rm" "rip" "touch" "chmod" "chown" "ln" "ouch" "xdg-open"];
              git-diff = ["git add" "git restore" "git diff"];
              git-branch = ["git checkout" "git switch" "git branch" "git merge" "git rebase" "git pull" "git push"];
              git-log = ["git log" "git show" "git revert" "git cherry-pick" "git reset"];
              procs = ["kill"];
              tldr = ["tldr"];
            };
          };
        };

        # from the source: this television doesn't install its cable dir
        channels =
          lib.genAttrs [
            "fish-history"
            "zoxide"
            "procs"
            "alias"
            "tldr"
            "man-pages"
            "systemd-units"
            "journal"
            "git-stash"
            "git-worktrees"
            "todo-comments"
          ] (name: "${pkgs.television.src}/cable/unix/${name}.toml")
          // {
            nix = {
              metadata = {
                name = "nix";
                requirements = ["nix-search-tv"];
              };
              source.command = "nix-search-tv print";
              preview.command = "nix-search-tv preview {}";
            };
          };
      }
    ];

    tvInit = pkgs.runCommand "tv-init.fish" {} ''
      HOME=$TMPDIR ${television}/bin/tv init fish > $out
      # enter picks instead of running a channel's action (git-branch checks out)
      substituteInPlace $out --replace-fail \
        '--autocomplete-prompt "$current_prompt"' \
        "--autocomplete-prompt \"\$current_prompt\" --keybindings 'enter=\"confirm_selection\"'"
    '';
  in {
    users.defaultUserShell = pkgs.fish;

    environment.systemPackages = [
      btop
      tealdeer
      television
      pkgs.nix-search-tv

      # done is skipped: it does nothing over ssh
      pkgs.fishPlugins.autopair
      pkgs.fishPlugins.sponge
      pkgs.fishPlugins.humantime-fish
      pkgs.fishPlugins.colored-man-pages
    ];

    programs.fish.enable = true;

    # after zoxide's init, which defines its own zi
    programs.fish.interactiveShellInit = lib.mkOrder 1600 ''
      # ctrl-t completes from a channel picked by the command, ctrl-r history
      source ${tvInit}

      function __tv_insert
          printf "\n"
          set -l picks (tv $argv --inline --no-status-bar --keybindings 'enter="confirm_selection"')
          if set -q picks[1]
              commandline -i -- (string join ' ' -- (string escape -- $picks))' '
          end
          printf "\033[A"
          commandline -f repaint
      end

      # fzf.fish keys
      bind ctrl-alt-f '__tv_insert files'
      bind ctrl-alt-l '__tv_insert git-log'
      bind ctrl-alt-s '__tv_insert git-diff'
      bind ctrl-alt-p '__tv_insert procs'
      bind ctrl-v "__tv_insert env --source-output '{split:=:0}'"

      # zoxide's zi needs fzf
      function zi
          set -l dir (tv zoxide --input "$argv" --keybindings 'enter="confirm_selection"')
          and set -q dir[1]
          and z $dir
      end
    '';

    # native fish instead of fenv spawning bash at every start
    programs.fish.useBabelfish = true;

    # apropos and man -k; indexed by a service, not on every rebuild
    documentation.man.cache = {
      enable = true;
      generateAtRuntime = true;
    };
  };
}
