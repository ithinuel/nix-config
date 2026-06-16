{ pkgs, lib, llm-agents ? { }, veloren ? { }, ... }:
let
  my-veloren = pkgs.symlinkJoin {
    name = "veloren-with-desktop";

    paths = [
      veloren.packages.${pkgs.stdenv.hostPlatform.system}.veloren-voxygen
    ];

    postBuild = ''
      mkdir -p $out/share/applications
      mkdir -p $out/share/icons/hicolor/256x256/apps

      cp ${veloren}/assets/voxygen/net.veloren.veloren.desktop  $out/share/applications/
      cp ${veloren}/assets/voxygen/net.veloren.veloren.png $out/share/icons/hicolor/256x256/apps/net.veloren.veloren.png
    '';
  };
in
{
  home.packages = [
    pkgs.obsidian
    pkgs.vlc
    pkgs.slack
    pkgs.siril
    pkgs.stellarium
    pkgs.prismlauncher
    llm-agents.copilot-cli
    llm-agents.mistral-vibe
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.homebank
    pkgs.saleae-logic-2
    pkgs.synology-drive-client

    pkgs.freecad
    pkgs.kicad
    pkgs.calibre

    my-veloren
  ];
}
