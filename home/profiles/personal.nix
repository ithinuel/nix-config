{ pkgs, lib, llm-agents ? { }, ... }: {
  programs = {
    calibre.enable = pkgs.stdenv.hostPlatform.isLinux;
    element-desktop.enable = true;
    prismlauncher.enable = true;
  };
  home.packages = [
    pkgs.slack
    pkgs.homebank
    llm-agents.copilot-cli
    llm-agents.mistral-vibe
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.vlc
    pkgs.siril
    pkgs.stellarium

    pkgs.saleae-logic-2 # marked as only linux x86-64
    pkgs.synology-drive-client

    pkgs.freecad
    pkgs.kicad
  ];
}
