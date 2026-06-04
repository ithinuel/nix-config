{ pkgs, ... }:
let
  whatsapp-electron = pkgs.whatsapp-electron.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace src/index.js \
        --replace-fail 'webSecurity: false,' 'webSecurity: false, autoHideMenuBar: true, show: process.argv.includes("--start-visible"),'
      substituteInPlace package.json \
        --replace-fail '"version"' '"desktopName": "com.github.dagmoller.whatsapp-electron", "version"'
    '';
  });
  element-desktop = pkgs.element-desktop.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace apps/desktop/package.json \
        --replace-fail '"productName"' '"desktopName": "element-desktop", "productName"'
    '';
  });
  zoom-us = pkgs.zoom-us.override {
    pulseaudioSupport = true;
    xdgDesktopPortalSupport = true;
    gnomeXdgDesktopPortalSupport = true;
  };
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
  programs.element-desktop = {
    enable = true;
    package = element-desktop;
  };
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
      element = mkAutostart { pkg = element-desktop; exec = "element-desktop"; flag = "--hidden"; };
      slack = mkAutostart { pkg = pkgs.slack; exec = "slack"; flag = "--startup"; };
      discord = mkAutostart { pkg = pkgs.discord; exec = "discord"; flag = "--start-minimized"; };
    in
    {
      enable = true;
      # Entries for obsidian and synology-drive-client are installed by the personal profile.
      entries = [
        "${pkgs.obsidian}/share/applications/obsidian.desktop"
        "${zoom-us}/share/applications/Zoom.desktop"
        "${discord}/discord.desktop"
        "${element}/element-desktop.desktop"
        "${slack}/slack.desktop"
        "${pkgs.synology-drive-client}/share/applications/synology-drive.desktop"
        "${whatsapp-electron}/share/applications/com.github.dagmoller.whatsapp-electron.desktop"
      ];
    };
}
