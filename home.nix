{ config, pkgs, lib, username, pathRoot, ... }:
let
  userBase = if pkgs.stdenv.isDarwin then "Users" else "home";
  homeDirectory = "/${userBase}/${username}";
in
{
  sops.age.keyFile = homeDirectory + "/.sops/age/keys.txt";
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

    # gui tools
    meld

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
  lib.optionals pkgs.stdenv.isLinux [
    firefox
    tilix

    usbutils
    xclip

    libreoffice
    ghex
  ] ++
  lib.optional (pkgs.stdenv.hostPlatform.system == "x86_64-linux") gcc_multi ++
  lib.optionals ((username == "ithinuel") && (pkg.stdenv.hostPlatform.system != "aarch64-darwin")) [
    freecad
    kicad
    calibre
  ] ++
  lib.optionals (pkgs.stdenv.hostPlatform.system != "aarch64-darwin") [
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
  };

  home.sessionVariables = {
    LESS = if pkgs.stdenv.isDarwin then "--mouse" else "";
    TCLLIBPATH = "${pkgs.awthemes}";
  };

  xdg.mimeApps = lib.attrsets.optionalAttrs (lib.strings.hasSuffix "-linux" pkgs.stdenv.hostPlatform.system) {
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
  programs.nixvim = import ./nixvim.nix { inherit pkgs lib; };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;

    shellAliases = {
      gs = "git submodule";
      gk = "gitk --all --branches --word-diff";
      gg = "lazygit";
      gdto = "git difftool -y";
      gsta = "git stash push --keep-index";
      gsti = "gst --ignored";
      gfa = "git fetch --all --recurse-submodules --prune";
      gbvv = "git branch -vv";
      gpristine = "git reset --hard && git clean --force -dfx -e .direnv -e .pre-commit-config.yaml";

      fd = "fd -H";
      ll = "eza -l --git";
      lla = "eza -la --git";
      ls = "eza";
      lsa = "eza -lah --git";
      cat = "bat -p";
      lg = "lazygit";
      du = "dust --reverse";

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

  programs.bat.enable = true;
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    silent = true;
  };
  programs.eza.enable = true;
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
      rebase.autoSquash = true;
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
  programs.htop.enable = true;
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

  services.home-manager.autoExpire.enable = pkgs.stdenv.isLinux;
}
