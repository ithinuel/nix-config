{ config, pathRoot, username, ... }:
let
  limit = {
    context = 256 * 1024;
    output = 32 * 1024;
  };
  limit-1M = limit // {
    context = 1024 * 1024;
  };
in
{
  sops.secrets.ha-mcp-key.sopsFile = pathRoot + "/secrets/global.${username}.ha-mcp-key.enc.yaml";
  sops.secrets.github-mcp-key.sopsFile = pathRoot + "/secrets/global.${username}.github-mcp-key.enc.yaml";
  programs.opencode.settings = {
    policies = [
      { action = "provider.use"; resource = "*"; effect = "deny"; }
      { action = "provider.use"; resource = "Ithinuel's AI"; effect = "allow"; }
      { action = "provider.use"; resource = "github-copilot"; effect = "allow"; }
    ];
    compaction.buffer = "16000";
    providers = {
      "Ithinuel's AI" = {
        package = "@opencode/ai/providers/openai-compatible";
        settings.baseURL = "https://llm.home.ithinuel.me/v1";
        models = {
          "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL" = { inherit limit-1M; };
          "unsloth/Qwen3.8-Flash-Next-GGUF:Q4_K_XL" = { inherit limit; };
          "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL" = { inherit limit; };
        };
      };
    };
    mcp.servers = {
      github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp";
        headers.Authorization = "Bearer {file:${config.sops.secrets.github-mcp-key.path}}";
      };
      home-assistant = {
        type = "remote";
        url = "https://ha.home.ithinuel.me/api/mcp";
        headers.Authorization = "Bearer {file:${config.sops.secrets.ha-mcp-key.path}}";
      };
    };
  };
}
