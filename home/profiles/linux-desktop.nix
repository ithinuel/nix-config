{ pkgs, inputs, ... }:
let
  unstable_pkgs = import inputs.nixpkgs-unstable {
    inherit (pkgs) config;
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  whatsapp-electron = unstable_pkgs.whatsapp-electron.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace src/main.js --replace-fail 'webSecurity: false,' 'webSecurity: false, autoHideMenuBar: true,'
    '';
  });
  zoom-us = pkgs.zoom-us.override { gnomeXdgDesktopPortalSupport = true; };
  mkAutostart = { pkg, src ? "share/applications/${exec}.desktop", exec, flag }:
    pkgs.runCommand "${exec}-autostart" { } ''
      mkdir -p "$out"
      sed "s|^Exec=\(.*\)|Exec=\1 ${flag}|" < "${pkg}/${src}" > "$out/${exec}.desktop"
    '';
in
{
  home.packages = [
    pkgs.slack
    whatsapp-electron
    zoom-us
  ];

  programs.obs-studio.enable = true;
  programs.discord.enable = true;
  programs.element-desktop.package = pkgs.element-desktop;
  programs.gnome-shell = {
    enable = true;
    extensions = [
      { package = pkgs.gnomeExtensions.appindicator; }
      { package = pkgs.gnomeExtensions.bluetooth-battery-meter; }
      { package = pkgs.gnomeExtensions.clipboard-indicator; }
      { package = pkgs.gnomeExtensions.razer-puppy; }
      { package = pkgs.gnomeExtensions.vitals; }
    ];
  };

  xdg.autostart =
    let
      element = mkAutostart { pkg = pkgs.element-desktop; exec = "element-desktop"; flag = "--hidden"; };
      slack = mkAutostart { pkg = pkgs.slack; exec = "slack"; flag = "--startup"; };
      discord = mkAutostart { pkg = pkgs.discord; exec = "discord"; flag = "--start-minimized"; };
      whatsapp = mkAutostart { pkg = whatsapp-electron; exec = "com.github.dagmoller.whatsapp-electron"; flag = "--start-in-tray"; };
    in
    {
      enable = true;
      # Entries for obsidian and synology-drive-client are installed by the personal profile.
      entries = [
        "${pkgs.obsidian}/share/applications/md.obsidian.Obsidian.desktop"
        "${zoom-us}/share/applications/Zoom.desktop"
        "${discord}/discord.desktop"
        "${element}/element-desktop.desktop"
        "${slack}/slack.desktop"
        "${pkgs.synology-drive-client}/share/applications/synology-drive.desktop"
        "${whatsapp}/share/applications/com.github.dagmoller.whatsapp-electron.desktop"
      ];
    };
}
