{ pkgs, lib, llm-agents ? { }, ... }: {
  home.packages = [
    pkgs.slack
    pkgs.homebank
    pkgs.prismlauncher
    pkgs.element-desktop
    llm-agents.copilot-cli
    llm-agents.mistral-vibe
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.vlc
    pkgs.siril
    pkgs.stellarium

    pkgs.homebank
    pkgs.saleae-logic-2 # marked as only linux x86-64
    pkgs.synology-drive-client

    pkgs.freecad
    pkgs.kicad
    pkgs.calibre
  ];
}
