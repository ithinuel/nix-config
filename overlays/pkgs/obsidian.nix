# Electron takes the Wayland app_id / X11 WM_CLASS from the `desktopName`
# field in the app's package.json (inside app.asar), which Obsidian sets to
# "md.obsidian.Obsidian.desktop". gnome-shell matches Wayland windows to the
# desktop file whose *basename* equals the app_id, so nixpkgs'
# obsidian.desktop (StartupWMClass=md.Obsidian) matches neither the basename
# nor the class — the window stays untracked (generic icon, cannot pin).
# Rename the desktop file to the app's real identity, like Flathub does, and
# correct StartupWMClass for X11/XWayland sessions.
{ obsidian, stdenv }:
if stdenv.hostPlatform.isDarwin then obsidian
else
  obsidian.overrideAttrs (_finalAttrs: previousAttrs: {
    postInstall = (previousAttrs.postInstall or "") + ''
      mv "$out/share/applications/obsidian.desktop"  "$out/share/applications/md.obsidian.Obsidian.desktop"
      substituteInPlace "$out/share/applications/md.obsidian.Obsidian.desktop" \
        --replace-fail 'StartupWMClass=md.Obsidian' 'StartupWMClass=md.obsidian.Obsidian'
    '';
  })
