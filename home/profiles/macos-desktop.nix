{ pkgs, ... }: {
  home.packages = [
    pkgs.iterm2
    pkgs.whatsapp-for-mac
    pkgs.chatgpt

    # TODO: add when available in nixpkgs:
    #   Claude
  ];
}
