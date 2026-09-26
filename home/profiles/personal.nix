{ pkgs, lib, inputs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux system;
  llm-agents = inputs.llm-agents.packages.${system};
in
{
  programs = {
    calibre.enable = isLinux;
    element-desktop.enable = true;
    prismlauncher.enable = true;
    opencode.settings = {
      subagent_depth = 0;
      provider = {

        "Ithinuel's AI" = {
          npm = "@ai-sdk/openai-compatible";
          options.baseURL = "https://ollama.home.ithinuel.me/v1";
          models = {
            "gemma4:12b" = { };
            "qwen3.5:9b" = { };
          };
        };
      };
    };
  };
  home.packages = [
    pkgs.slack
    pkgs.homebank
    llm-agents.copilot-cli
    llm-agents.mistral-vibe
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
