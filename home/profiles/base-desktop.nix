{ pkgs, lib, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in
{
  home.packages = with pkgs; [
    # gui tools
    meld
    obsidian
    (if isDarwin then vlc-bin else vlc)
    (if isDarwin then libreoffice-bin else libreoffice)
    firefox
    wireshark

    awthemes
  ] ++
  lib.optionals isLinux [
    gimp-with-plugins
    ghex
  ];

  home.sessionVariables.TCLLIBPATH = "${pkgs.awthemes}";

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
}
