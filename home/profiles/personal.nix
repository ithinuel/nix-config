{ pkgs, lib, llm-agents ? { }, ... }: {
  home.packages = [
    pkgs.obsidian
    pkgs.vlc
    pkgs.slack
    pkgs.siril
    pkgs.stellarium
    llm-agents.copilot-cli
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.homebank
    pkgs.saleae-logic-2
    pkgs.synology-drive-client

    pkgs.freecad
    pkgs.kicad
    pkgs.calibre
  ];
}
