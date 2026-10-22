{ config, inputs, pathRoot, pkgs, username, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  llm-agents = inputs.llm-agents.packages.${system};
  model-config = {
    limit = {
      context = 1024 * 1024;
      output = 32 * 1024;
    };
  };
in
{
  sops.secrets.ha-mcp-key.sopsFile = pathRoot + "/secrets/global.${username}.ha-mcp-key.enc.yaml";
  sops.secrets.github-mcp-key.sopsFile = pathRoot + "/secrets/global.${username}.github-mcp-key.enc.yaml";
  programs.opencode.settings = {
    enabled_providers = [ "Ithinuel's AI" "github-copilot" ];
    provider = {
      "Ithinuel's AI" = {
        npm = "@ai-sdk/openai-compatible";
        options.baseURL = "https://llm.home.ithinuel.me/v1";
        models = {
          "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL" = model-config;
          "unsloth/Qwen3.8-Flash-Next-GGUF:Q4_K_XL" = { };
          "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL" = { };
        };
      };
    };
    mcp = {
      github = {
        enabled = true;
        type = "remote";
        url = "https://api.githubcopilot.com/mcp";
        headers.Authorization = "Bearer {file:${config.sops.secrets.github-mcp-key.path}}";
      };
      home-assistant = {
        enabled = true;
        type = "remote";
        url = "https://ha.home.ithinuel.me/api/mcp";
        headers.Authorization = "Bearer {file:${config.sops.secrets.ha-mcp-key.path}}";
      };
    };
  };
  home.packages = [ llm-agents.copilot-cli ];
}
