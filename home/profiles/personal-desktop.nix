{ pkgs, lib, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  programs = {
    calibre.enable = isLinux;
    element-desktop.enable = true;
    prismlauncher.enable = true;
  };
  home.packages = [
    pkgs.slack
    pkgs.homebank
    pkgs.telegram-desktop
  ] ++ lib.optionals isLinux [
    pkgs.vlc
    pkgs.siril
    pkgs.stellarium

    pkgs.saleae-logic-2 # marked as only linux x86-64
    pkgs.synology-drive-client

    pkgs.freecad
    pkgs.kicad
  ];
}
