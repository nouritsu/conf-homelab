# conf-nixos' packages/starship/modules/settings.nix, as a plain wrapper module
{lib, ...}: {
  settings = let
    symbols = {
      sudo = "#";
      status = {
        success = " ";
        failure = " ";
        not_executable = " ";
        not_found = " ";
        sig_int = "C-c";
        signal = "󱐋";
      };
      separator = "//";
      separator_bottom = "─";
      character = rec {
        success = "❯";
        error = success;
      };
      directory = {
        read_only = " 󰉐 ";
        truncation = "(..)/";
      };
      battery = {
        full = "󰁹";
        charging = "󰂄";
        unknown = "󰂑";
        empty = "󰂎";

        "10" = "󰁺";
        "20" = "󰁻";
        "30" = "󰁼";
        "40" = "󰁽";
        "50" = "󰁾";
        "60" = "󰁿";
        "70" = "󰂀";
        "80" = "󰂁";
        "90" = "󰂂";
        "100" = symbols.battery.full;
      };

      git_branch = " ";

      cpu_usage = "󰻠 ";

      memory_usage = "  ";

      load = "󰓅 ";

      nix_shell = " ";
    };

    colors = {
      sudo = "bold yellow";
      status = {
        default = "bold red";
        success = "bold blue";
        failure = "bold bright-red";
      };
      os = "bold blue";
      character = {
        success = "bold white";
        error = "bold red";
      };
      username = {
        user = "mauve bold";
        root = "red bold";
      };
      hostname = "bold green";
      directory = {
        default = "bold green";
        read_only = "bold red";
      };
      separator = "bold white";

      time = "bold yellow";

      cmd_duration = "bold yellow";

      battery = {
        full = "bold bright-green";
        charging = "bold bright-blue";
        discharging = "bold red";
        unknown = "bold yellow";
        empty = "bold black";

        "10" = "bold red";
        "20" = "bold red";
        "30" = "bold bright-red";
        "40" = "bold yellow";
        "50" = "bold yellow";
        "60" = "bold bright-yellow";
        "70" = "bold green";
        "80" = "bold green";
        "90" = "bold bright-green";
        "100" = "bold bright-green";
      };

      git_branch = "bold mauve";

      git_metrics = {
        added = "bold green";
        deleted = "bold red";
      };

      git_status = "bold mauve";

      jobs = "bold mauve";

      cpu_usage = {
        cpu = "bold sapphire";
        percent = "bold black";
      };

      memory_usage = {
        memory = "bold yellow";
        percent = "bold black";
      };

      load = {
        load = "bold peach";
        value = "bold black";
      };

      nix_shell = {
        default = "bold blue";
        state = "bold red";
      };
    };

    styled = {
      separator = "[${symbols.separator}](${colors.separator})";
      separator_bottom = "[${symbols.separator_bottom}](${colors.separator})";
    };

    to_display = percentage: {
      threshold = percentage;
      style = colors.battery.${toString percentage};
      discharging_symbol = symbols.battery.${toString percentage};
    };

    replicate = n: str: lib.concatStrings (lib.replicate n str);
    surround = using_l: using_r: color: padding: this: "[\\${using_l}](${color})${replicate padding " "}${this}${replicate padding " "}[\\${using_r}](${color})";
    surround_paren = this: color: padding: surround "(" ")" color padding this;
    surround_bracket = this: color: padding: surround "[" "]" color padding this;
  in {
    add_newline = false;
    command_timeout = 2000;

    format = lib.concatStrings [
      "[╭](${colors.separator})"
      "${surround_bracket "$username@$hostname" colors.separator 0} "
      "$time"
      "$battery"
      "$directory"
      "$git_metrics"
      "$git_branch"
      "$git_status"
      "$cmd_duration"
      "$line_break"
      "[╰](${colors.separator})"
      "\${custom.cpu}"
      "$memory_usage"
      "\${custom.load}"
      "$nix_shell"
      "$jobs"
      "$status"
      "$sudo"
      "$character"
    ];

    character = {
      disabled = false;
      success_symbol = "[${symbols.character.success}](${colors.character.success})";
      error_symbol = "[${symbols.character.error}](${colors.character.error})";
    };

    battery = {
      disabled = true;
      format = "${styled.separator} [$symbol]($style) $percentage ";

      full_symbol = symbols.battery.full;
      charging_symbol = symbols.battery.charging;
      unknown_symbol = symbols.battery.unknown;
      empty_symbol = symbols.battery.empty;

      display =
        map
        to_display [
          10
          20
          30
          40
          50
          60
          70
          80
          90
          100
        ];
    };

    status = {
      disabled = false;
      format = "${styled.separator_bottom}${surround_paren "[$symbol$maybe_int]($style)" colors.separator 0}";

      style = colors.status.default;
      success_style = colors.status.success;
      failure_style = colors.status.failure;

      symbol = symbols.status.failure;
      success_symbol = symbols.status.success;
      not_executable_symbol = symbols.status.not_executable;
      not_found_symbol = symbols.status.not_found;
      sigint_symbol = symbols.status.sig_int;
      signal_symbol = symbols.status.signal;

      map_symbol = true;
    };

    time = {
      disabled = true;
      style = colors.time;
      format = "${styled.separator} [$time]($style) ";
      time_format = "%R";
    };

    username = {
      disabled = false;
      show_always = true;
      style_user = colors.username.user;
      style_root = colors.username.root;
      format = "[$user]($style)";
    };

    hostname = {
      disabled = false;
      ssh_only = false;
      style = colors.hostname;
      format = "[$hostname]($style)";
    };

    directory = {
      disabled = false;
      format = "${styled.separator} [$path]($style)[$read_only]($read_only_style) ";
      style = colors.directory.default;

      truncate_to_repo = false;
      truncation_symbol = symbols.directory.truncation;

      read_only = symbols.directory.read_only;
      read_only_style = colors.directory.read_only;
    };

    cmd_duration = {
      disabled = false;
      min_time = 1000;
      format = "${styled.separator} took [$duration]($style) ";
      show_milliseconds = true;
      style = colors.cmd_duration;
    };

    git_branch = {
      disabled = false;
      format = "on [$symbol$branch(:$remote_branch)]($style) ";
      symbol = symbols.git_branch;
      style = colors.git_branch;
      ignore_branches = ["master" "main"];
    };

    git_metrics = {
      disabled = false;
      only_nonzero_diffs = false;
      format = "${styled.separator} ${surround_bracket "[+$added]($added_style) [-$deleted]($deleted_style)" colors.separator 0} ";
      added_style = colors.git_metrics.added;
      deleted_style = colors.git_metrics.deleted;
    };

    git_status = {
      disabled = false;
      format = "([$all_status$ahead_behind]($style) )";
      style = colors.git_status;
    };

    sudo = {
      disabled = false;
      format = "${styled.separator_bottom}${surround_paren "[$symbol]($style)" colors.separator 0}";
      symbol = symbols.sudo;
      style = colors.sudo;
      allow_windows = true;
    };

    jobs = rec {
      disabled = false;
      format = "${styled.separator_bottom}${surround_paren "[+$number]($style)" colors.separator 0}";
      symbol = "";
      style = colors.jobs;
      number_threshold = 1;
      symbol_threshold = number_threshold;
    };

    custom.cpu = {
      disabled = true;
      when = true;
      shell = ["sh"];
      command = ''
        read -r _ u n s i w q r t _ </proc/stat
        a=$((u + n + s + i + w + q + r + t)) b=$((i + w))
        sleep 0.1
        read -r _ u n s i w q r t _ </proc/stat
        a=$((u + n + s + i + w + q + r + t - a)) b=$((i + w - b))
        echo "$((100 * (a - b) / a))%"
      '';
      format = "${styled.separator_bottom}${surround_paren "[$symbol](${colors.cpu_usage.cpu})[$output]($style)" colors.separator 0}";
      symbol = symbols.cpu_usage;
      style = colors.cpu_usage.percent;
    };

    memory_usage = {
      disabled = true;
      format = "${styled.separator_bottom}${surround_paren "[$symbol](${colors.memory_usage.memory})[$ram_pct]($style)" colors.separator 0}";
      symbol = symbols.memory_usage;
      style = colors.memory_usage.percent;
      threshold = -1;
    };

    custom.load = {
      disabled = true;
      when = true;
      shell = ["sh"];
      command = "read -r l _ </proc/loadavg; echo $l";
      format = "${styled.separator_bottom}${surround_paren "[$symbol](${colors.load.load})[$output]($style)" colors.separator 0}";
      symbol = symbols.load;
      style = colors.load.value;
    };

    nix_shell = {
      disabled = false;
      format = "${styled.separator_bottom}${surround_bracket "[$symbol]($style)[$state](${colors.nix_shell.state})" colors.separator 0}";
      symbol = symbols.nix_shell;
      style = colors.nix_shell.default;
    };
  };
}
