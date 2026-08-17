{ config, pkgs, lib, username, pathRoot, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux isx86_64;
  userBase = if isDarwin then "Users" else "home";
  homeDirectory = "/${userBase}/${username}";
in
{
  sops.age.keyFile = homeDirectory + "/.config/sops/age/keys.txt";
  sops.secrets.allowed_signers = {
    sopsFile = pathRoot + "/secrets/allowed_signers.sops";
    format = "binary";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
  home.username = username;
  home.homeDirectory = homeDirectory;

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # terminal tools
    docker
    docker-credential-helpers
    file
    graphviz
    unixtools.xxd
    sops
    age
    ssh-to-age
    tree
    dust

    # extratools for coding
    pyright
    mypy

    # embedded dev tools
    libstatgrab
    minicom
    clang-tools
    cmake-format
    gdb
    gdb-dashboard

    # gui tools
    meld
    obsidian
    (if isDarwin then vlc-bin else vlc)
    (if isDarwin then libreoffice-bin else libreoffice)
    (if isDarwin then firefox-bin else firefox)
    wireshark

    # Rust accelerated cli tools
    bacon
    cargo-watch

    # Nix language server
    nixd
    nixpkgs-fmt
    nix-tree
    nvd

    # custom packages
    awthemes
  ] ++
  lib.optionals isLinux [
    usbutils

    ghex
  ] ++
  lib.optional (isLinux && isx86_64) gcc_multi;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    ".Xresources".text = "*TkTheme: awdark";
    ".gdbinit".text = ''
      set print pretty on

      python

      import os

      gdb.execute('source ${pkgs.gdb-dashboard.outPath}/.gdbinit')

      end
    '';
  };

  home.sessionVariables = {
    LESS = if isDarwin then "--mouse" else "";
    TCLLIBPATH = "${pkgs.awthemes}";
  };

  xdg.mimeApps = lib.attrsets.optionalAttrs isLinux {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "application/pdf" = [ "evince.desktop" "firefox.desktop" ];
    };
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
  programs.nixvim = import ../nixvim.nix { inherit pkgs lib; };
  programs.ghostty = {
    enable = true;
    package = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    settings = {
      theme = "Adwaita Dark";
      focus-follows-mouse = true;
      background-opacity = 0.95;
      background-blur-radius = 20;
      shell-integration-features = "ssh-terminfo,ssh-env";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;

    shellAliases = import ./shell-aliases.nix { inherit lib; };

    history = {
      size = 1000000;
      ignoreDups = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
      expireDuplicatesFirst = true;
    };

    plugins = [{
      # zsh-autocomplete triggers asynchronously as I type, noneed for double-tab.
      name = "zsh-autocomplete";
      src = pkgs.zsh-autocomplete;
      file = "share/zsh-autocomplete/zsh-autocomplete.plugin.zsh";
    }];
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = ''
        $cmd_duration$status$fill $time $fill ($python )$username@$hostname
        ($direnv )$directory $character
      '';
      right_format = ''([ \($git_branch( $git_status)\)](bright-blue))'';

      character = {
        success_symbol = "[»](bold 105)";
        error_symbol = "[»](bold red)";
        vimcmd_symbol = "[»](bold blue)";
      };

      cmd_duration = {
        min_time = 0;
        format = "[$duration]($style) ";
        style = "bright-black";
        show_notifications = true;
      };

      directory = {
        format = "[$path]($style)[$read_only]($read_only_style)";
        style = "bold 32";
        home_symbol = "~";
        truncation_length = 0;
        truncate_to_repo = false;
        read_only = " 🔒";
        read_only_style = "red";
      };

      direnv = {
        disabled = false;
        format = "$allowed";
        allowed_msg = " ";
        not_allowed_msg = " ";
        denied_msg = " ";
      };

      fill = {
        symbol = "-";
        style = "237";
      };

      git_branch = {
        format = ''[$branch](bright-red)'';
        style = "bright-blue";
        truncation_length = 20;
        truncation_symbol = "…";
      };

      git_status = {
        format = "$all_status$ahead_behind";
        ahead = "⇡$count";
        diverged = "⇕⇡$ahead_count⇣$behind_count";
        behind = "⇣$count";
        conflicted = "🏳";
        up_to_date = "✓";
        untracked = "🤷";
        stashed = "📦";
        modified = "📝";
        staged = "[++\($count\)](green)";
        renamed = "👅";
        deleted = "🗑";
      };

      hostname = {
        ssh_only = false;
        format = "[$hostname]($style)";
        style = "bright-black";
      };

      python = {
        format = "[\\($symbol$virtualenv\\)](bright-black)";
      };

      status = {
        format = "[↵ $status]($style) ";
        style = "red";
        disabled = false;
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "bright-black";
      };

      username = {
        show_always = true;
        format = "[$user]($style)";
        style_user = "bright-black";
        style_root = "bright-red";
      };
    };
  };

  programs.bat.enable = true;
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };
  programs.fd.enable = true;
  programs.gh.enable = true;
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;

    settings = {
      user.name = "Wilfried Chauveau";
      user.email = let user = "wilfried.chauveau"; domain = "ithinuel.me"; in "${user}@${domain}";
      init.defaultBranch = "main";
      rebase = {
        autoSquash = true;
        updateRefs = true;
      };
      log.showSignature = true;

      gpg.ssh.allowedSignersFile = config.sops.secrets.allowed_signers.path;

      gui.tabsize = 4;
    };
    ignores = [ ".direnv" ".DS_Store" ".pre-commit-config.yaml" ];
    signing.signByDefault = true;
    signing.key = null;
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options.side-by-side = true;
  };

  programs.gpg.enable = true;
  programs.btop.enable = true;
  programs.htop = {
    enable = true;
    settings = {
      show_program_path = false;
    } // (
      let mkSet = list: lib.genAttrs list (_: true);
      in mkSet [
        "hide_userland_threads"
        "highlight_base_name"
        "shadow_distribution_path_prefix"
        "highlight_changes"
        "show_merged_command"
        "hide_function_bar"
        "tree_view"
      ]
    );
  };
  programs.lazydocker.enable = true;
  programs.lazygit = {
    enable = true;
    settings.git = {
      overrideGpg = true;
      commit.signOff = true;
    };
  };
  programs.ripgrep = {
    enable = true;
    arguments = [
      "-p"
      "--no-heading"
      "--follow"
      "--type-add=kconf:Kconfig"
      "--type-add=dtss:*.dts"
      "--type-add=dtsi:*.dtsi"
      "--type-add=dts:include:dtss,dtsi"
      "--type-add=ld:*.ld"
      "--type-add=rustld:*.x"
      "--type-add=linker:include:ld,rustld"
    ];
  };
  home.file.".rgignore".text = ''
    !.gitlab
    !.github
  '';
  programs.ruff.enable = true;
  programs.ruff.settings = { };
  programs.nix-index.enable = true;
  programs.carapace.enable = true;

  services.home-manager.autoExpire.enable = isLinux;
}
