{
  # unload the models after 30min
  extraFlags = [ "--models-max" "2" "--sleep-idle-seconds" "1800" ];
  modelsPreset = {
    "unsloth/Qwen3.5-9B-GGUF:Q4_K_XL" = {
      hf-repo = "unsloth/Qwen3.5-9B-GGUF:Q4_K_XL";
      temperature = 0.6;
      top-p = 0.95;
      top-k = 20;
      min-p = 0.0;
      presence-penalty = 0.0;
      repeat-penalty = 1.0;
      ctx-size = 256 * 1024;
    };
    "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL" = {
      hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q8_K_XL";
      temperature = 0.6;
      top-p = 0.95;
      top-k = 20;
      min-p = 0.0;
      presence-penalty = 0.0;
      repeat-penalty = 1.0;
      flash-attn = "on";

      # This causes the model to spiral in thinking loops.
      #chat-template-kwargs = "{\"preserve_thinking\": \"true\"}";

      # enable MTP
      spec-type = "draft-mtp";
      spec-draft-n-max = 5;

      # enable 1M context with RoPE
      rope-scaling = "yarn";
      rope-scale = 4;
      yarn-orig-ctx = 256 * 1024;
      ctx-size = 1024 * 1024;
    };
    "unsloth/Qwen3.8-27B-GGUF:UD-Q4_0" = {
      hf-repo = "unsloth/Qwen3.8-27B-GGUF:Q4_0";
      hf-repo-draft = "unsloth/Qwen3.8-27B-GGUF:Q4_0";
      model-draft = "MTP/mtp-Qwen3.8-27B-Q4_0.gguf";

      temp = 1.0;
      top-p = 0.95;
      top-k = 20;
      min-p = 0;
      presence-penalty = 0.0;
      repeat-penalty = 1.0;

      rope-scaling = "yarn";
      rope-scale = 4;
      yarn-orig-ctx = 256 * 1024;

      spec-type = "draft-mtp";
      spec-draft-n-max = 3;

      # adjust rollback (when MTP prediction is rejected)
      ctx-checkpoints = 8;
      checkpoint-min-step = 32768;

      cache-type-k = "q4_0";
      cache-type-v = "q4_0";
      ctx-size = 1024 * 1024;
    };
    "unsloth/Qwen3.8-Flash-Next-GGUF:UD-Q3_K_XL" = {
      hf-repo = "unsloth/Qwen3.8-Flash-Next-GGUF:UD-Q3_K_XL";

      temp = 1.0;
      top-p = 0.95;
      top-k = 20;
      min-p = 0;
      presence-penalty = 0.0;
      repeat-penalty = 1.0;

      ctx-size = 256 * 1024;
    };
    "unsloth/gemma-4-12b-it-GGUF:Q4_K_XL" = {
      hf-repo = "unsloth/gemma-4-12b-it-GGUF:Q4_K_XL";
      temp = 1.0;
      top-p = 0.95;
      top-k = 64;
      ctx-size = 256 * 1024;
    };
    "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL" = {
      hf-repo = "unsloth/gemma-4-26B-A4B-it-GGUF:Q4_K_XL";
      spec-type = "draft-mtp";
      spec-draft-n-max = 2;
      temp = 1.0;
      top-p = 0.95;
      top-k = 64;
      ctx-size = 256 * 1024;
    };
    "PaddlePaddle/PaddleOCR-VL-1.6-GGUF" = {
      hf-repo = "PaddlePaddle/PaddleOCR-VL-1.6-GGUF";
      temp = 0;
    };
    "zai-org/GLM-OCR" = {
      hf-repo = "zai-org/GLM-OCR";
      temp = 0;
    };
  };
}
