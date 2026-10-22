{ config, lib, pathRoot, pkgs, username, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  sops.secrets.obsidian-mcp-key.sopsFile = pathRoot + "/secrets/global.${username}.obsidian-mcp-key.enc.yaml";
  programs = {
    calibre.enable = isLinux;
    element-desktop.enable = true;
    prismlauncher.enable = true;
    opencode.settings.mcp.obsidian = {
      enabled = true;
      type = "remote";
      url = "http://127.0.0.1:27124/mcp/";
      headers.Authorization = "Bearer {file:${config.sops.secrets.obsidian-mcp-key.path}}";
    };
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
