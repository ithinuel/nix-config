{ config, pkgs, lib, username, pathRoot, ... }:
let userBase = if pkgs.stdenv.isDarwin then "Users" else "home";
in {
  sops.gnupg.home = "${config.home.homeDirectory}/.gnupg";
  sops.secrets.allowed_signers = {
    sopsFile = pathRoot + "/secrets/allowed_signers";
    format = "binary";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
  home.username = username;
  home.homeDirectory = "/${userBase}/${username}";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # terminal tools
    zsh
    htop
    docker
    docker-credential-helpers
    file
    graphviz
    unixtools.xxd
    gh
    sops
    ssh-to-age

    # extratools for coding
    pyright
    mypy

    # embedded dev tools
    libstatgrab
    minicom
    clang-tools
    cmake-format

    # gui tools
    meld

    # Rust accelerated cli tools
    rustup
    ripgrep
    skim
    bat
    bacon
    cargo-watch
    ruff

    # Nix language server
    nixd
    nixpkgs-fmt
    nix-tree
    nvd

    # custom packages
    awthemes
    nerdfonts
    eza
    fd-find
  ] ++
  lib.optionals pkgs.stdenv.isLinux [
    firefox
    tilix

    usbutils
    xclip

    libreoffice
    ghex
  ] ++
  lib.optional (pkgs.system == "x86_64-linux") gcc_multi ++
  lib.optionals ((username == "ithinuel") && (pkg.system != "aarch64-darwin")) [
    freecad
    kicad
    calibre
  ] ++
  lib.optionals (pkgs.system != "aarch64-darwin") [
    gdb
    gdb-dashboard
  ];

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


    ".config/ripgreprc".text = ''
      -p
      --no-heading
      --follow
      --type-add=kconf:Kconfig
      --type-add=dtss:*.dts
      --type-add=dtsi:*.dtsi
      --type-add=dts:include:dtss,dtsi
      --type-add=ld:*.ld
      --type-add=rustld:*.x
      --type-add=linker:include:ld,rustld
    '';

    ".rgignore".text = ''
      !.gitlab
      !.github
    '';
  };

  home.sessionVariables = {
    LESS = if pkgs.stdenv.isDarwin then "--mouse" else "";
    TCLLIBPATH = "${pkgs.awthemes}";
    RIPGREP_CONFIG_PATH = "\${HOME}/.config/ripgreprc";
  };

  xdg.mimeApps = lib.attrsets.optionalAttrs (lib.strings.hasSuffix "-linux" pkgs.system) {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "application/pdf" = [ "evince.desktop" "firefox.desktop" ];
    };
  };

  dconf = {
    enable = pkgs.stdenv.isLinux;
    settings = {
      "org/gnome/GHex" = {
        group-data-by = "longwords";
        show-offsets = true;
      };
      "org/gnome/meld" = {
        show-line-numbers = true;
        wrap-mode = "none";
      };
    };
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
  programs.neovim = {
    enable = true;
    withNodeJs = true;
    withPython3 = true;
    defaultEditor = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      vim-bufkill
      vim-fugitive
      vim-just
      vim-markdown
      vim-signify
      nvim-surround
      nvim-autopairs
      which-key-nvim

      ctrlp-vim
      skim
      fzf-vim
      file-line
      nerdcommenter
      markdown-preview-nvim
      tabular

      vim-airline
      vim-airline-themes

      coc-clangd
      coc-cmake
      coc-docker
      coc-git
      coc-json
      coc-lua
      coc-markdownlint
      coc-pyright
      coc-ruff
      coc-rust-analyzer
      coc-spell-checker
      coc-toml
      coc-yaml
      coc-nvim

      copilot-vim
      coc-copilot

      #(vimPluginFromGitHub "LunarWatcher" "auto-pairs" "v4.0.2"
      #  "sha256-dxWcbmXPeq87vnUgNFoXIqhIHMjmYoab2vhm1ijp9MM")
      vim-archery
    ];

    extraConfig = builtins.readFile ./neovim.vim;
  };
  home.file.".config/nvim/coc-settings.json".source = config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.config/home-manager/home/coc-settings.json";
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;

    shellAliases = {
      gs = "git submodule";
      gk = "gitk --all --branches --word-diff";
      gg = "git gui";
      gdto = "git difftool -y";
      gsti = "gst --ignored";
      gfa = "git fetch --all --recurse-submodules --prune";
      gbvv = "git branch -vv";

      fd = "fd -H";
      ll = "eza -l --git";
      lla = "eza -la --git";
      ls = "eza";
      lsa = "eza -lah --git";
      cat = "bat -p";

      hme = "home-manager edit";
      hms = "home-manager switch";
      hm = "home-manager";
    };

    history.size = 1000000;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "dnf" "python" ];
      theme = "af-magic";
    };
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
    package = pkgs.gitFull;

    userName = "Wilfried Chauveau";
    userEmail = let user = "wilfried.chauveau"; domain = "ithinuel.me"; in "${user}@${domain}";
    ignores = [ ".direnv" ".DS_Store" ];
    signing.signByDefault = true;
    signing.key = null;

    delta.enable = true;
    delta.options.side-by-side = true;

    extraConfig = {
      init.defaultBranch = "main";
      rebase.autoSquash = true;
      log.showSignature = true;

      gpg.ssh.allowedSignersFile = config.sops.secrets.allowed_signers.path;

      gui.tabsize = 4;
    };
  };
  programs.gpg.enable = true;

  services.home-manager.autoExpire.enable = pkgs.stdenv.isLinux;
}
