{ pkgs, lib }: {
  enable = true;
  defaultEditor = true;


  vimAlias = true;
  colorschemes.nightfox = {
    enable = true;
    flavor = "duskfox";
  };

  plugins = {
    bufferline.enable = true;
    copilot-lua.settings = {
      suggestion.enabled = false;
      panel.enabled = false;
    };
    fugitive.enable = true;
    lazygit.enable = true;
    lspkind.enable = true;
    lsp-format.enable = true;
    lsp-status.enable = true;
    lsp.enable = true;
    lualine = {
      enable = true;
      settings.sections.lualine_x = [ "lsp_status" "filetype" ];
      # Could work with the following line but the render isn’t super nice.
      #settings.sections.lualine_x = [ "require('lsp-status').status()" "filetype" ];
    };
    markdown-preview = {
      enable = true;
      settings.auto_close = 0;
    };
    nvim-autopairs.enable = true;
    nvim-surround.enable = true;
    web-devicons.enable = true;
    which-key = {
      enable = true;
      settings.preset = "modern";
    };

    cmp = {
      enable = true;
      settings = {
        window.completion.border = "rounded";
        mapping = {
          "<Tab>" = "cmp.mapping.select_next_item()";
          "<S-Tab>" = "cmp.mapping.select_prev_item()";
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
        };
        sources = lib.map (name: { inherit name; }) [
          "nvim_lsp"
          "cmp-clippy"
          "conventionalcommits"
          #"copilot"
          "emoji"
          "git"
          "path"
          "spell"
          "buffer"
        ];
      };
    };
  };

  lsp = {
    inlayHints.enable = true;
    servers = {
      asm_lsp.enable = true;
      bashls.enable = true;
      bitbake_language_server.enable = pkgs.stdenv.isLinux;
      clangd.enable = true;
      cmake.enable = true;
      dockerls.enable = true;
      #gitlab_ci_ls.enable = true; # TODO: Enable when available
      jsonls.enable = true;
      just.enable = true;
      lua_ls.enable = true;
      pyright.enable = true;
      ruff.enable = true;
      # TODO: the default config doesn’t work great quite yet
      # see https://github.com/nix-community/nixvim/issues/3296
      #statix.enable = true;
      yamlls.enable = true;

      rust_analyzer = {
        enable = true;
      };
      nixd = {
        enable = true;
        settings.formatting.command = [ "nixpkgs-fmt" ];
      };
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    vim-bufkill
    vim-just

    ctrlp-vim
    file-line
    fzf-vim
    nerdcommenter
    skim
    tabular
  ];
  globals = {
    "ctrlp_types" = [ "buf" "mru" "fil" ];
    "ctrlp_open_multiple_files" = "i";
    "ctrlp_clear_cache_on_exit" = 0;
  };

  opts =
    let colorcolumn = "100," + (lib.concatStringsSep "," (lib.map builtins.toString (lib.range 120 499)));
    in {
      termguicolors = true;

      hidden = true;
      encoding = "utf-8";
      cursorline = true;

      inherit colorcolumn;
      wrap = false;
      sidescroll = 8;
      showbreak = "↪";

      viewoptions = [ "folds" "cursor" ];

      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      smartindent = true;

      foldmethod = "syntax";
      foldcolumn = "1";
      foldlevel = 99;

      ruler = true;
      number = true;

      smartcase = true;
      incsearch = true;
      hlsearch = true;

      mouse = "a";
      # enable pre-project vimrc
      exrc = true;

      wildmenu = true;
      wildmode = "full";
      wildignore = [ "*.a" "*.o" ]
        ++ [ "*.bmp" "*.gif" "*.ico" "*.jpg" "*.png" ]
        ++ [ ".DS_Store" ".git" ".hg" ".svn" ]
        ++ [ "*~" "*.swp" "*.tmp" ];

      list = true;
      listchars = "tab:»\ ,trail:·,nbsp:⎵,precedes:<,extends:>";
    };

  globals.mapleader = ",";
  keymaps = [
    { mode = "n"; key = "gp"; action = "<C-O>"; options.desc = "Goto the previous cursor positions."; }
    { mode = "x"; key = "p"; action = "pgvy"; options.desc = "re-yank what was pasted."; }

    # skim mapping (search in file names)
    { key = "<c-o>"; action = ":SK<CR>"; }
    { mode = "i"; key = "<C-o>"; action = "<Esc>:SK<CR>"; }

    # fzf mapping (search in files)
    { key = "<c-t>"; action = ":Rg<CR>"; }
    { mode = "i"; key = "<C-t>"; action = "<Esc>:Rg<CR>"; }

    # Lazygit in vim 🫨
    { mode = "n"; key = "<leader>gg"; action = ":LazyGit<CR>"; }

    # Buffer management
    { mode = "n"; key = "<C-S-Left>"; action = ":bp<CR>"; options = { desc = "Move to the previous buffer."; silent = true; }; }
    { mode = "n"; key = "<C-S-Right>"; action = ":bn<CR>"; options = { desc = "Move to the next buffer."; silent = true; }; }
    { mode = "i"; key = "<C-S-Left>"; action = "<Esc>:bp<CR>"; options = { desc = "Move to the previous buffer."; silent = true; }; }
    { mode = "i"; key = "<C-S-Right>"; action = "<Esc>:bn<CR>"; options = { desc = "Move to the next buffer."; silent = true; }; }
    { key = "<c-x>"; action = "<Plug>BufKillBangBd"; options = { desc = "Close the current buffer."; silent = true; }; }

    # lsp mapping
    { key = "gd"; action = ":lua vim.lsp.buf.definition()<CR>"; options = { desc = "go to definition with LSP"; silent = true; }; }
    { key = "<leader>rn"; action = ":lua vim.lsp.buf.rename()<CR>"; options.desc = "rename variable with LSP"; }
    { key = "<leader>ac"; action = ":lua vim.lsp.buf.code_action()<CR>"; options = { desc = "Triggers the code action menu."; silent = true; }; }
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # bépo remapped
    { key = "«"; action = "<"; }
    { key = "»"; action = ">"; }
    { key = "."; action = ":"; }
    { key = ":"; action = "."; }
  ];
  autoCmd = [
    # force filetype to be matched correctly
    { event = [ "BufNewFile" "BufRead" ]; pattern = [ ".vh" ".v" ]; command = "set filetype=verilog"; }
    # remove trailing spaces
    { event = [ "BufWritePre" ]; pattern = [ ".vh" ".v" "*.py" "*.c" "*.h" ]; command = ":%s/\\s\\+$//e"; }
    # Check spelling for markdown files
    { event = [ "BufRead" "BufNewFile" ]; pattern = [ "*.md" ]; command = "setlocal spell spelllang=en"; }
    # Auto format on save.
    { event = [ "BufWritePre" ]; pattern = [ "<buffer>" ]; command = "lua vim.lsp.buf.format({ async = false })"; }
  ];
}
