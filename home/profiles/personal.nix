{ pkgs, inputs, ... }:
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
  programs.opencode.settings = {
    enabled_providers = [ "Ithinuel's AI" "github-copilot" ];
    provider = {
      "Ithinuel's AI" = {
        npm = "@ai-sdk/openai-compatible";
        options.baseURL = "https://llm.home.ithinuel.me/v1";
        models = {
          "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_XL" = model-config;
          "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q8_K_XL" = model-config;
          "unsloth/Qwen3.8-27B-GGUF:Q4_0" = { };
          "unsloth/Qwen3.8-Flash-Next-GGUF:Q3_K_XL" = { };
          "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL" = { };
        };
      };
    };
  };
  home.packages = [ llm-agents.copilot-cli ];
}
