{ pkgs, lib }: {
  enable = true;
  vimAlias = true;
  defaultEditor = true;

  nixpkgs.pkgs = pkgs;

  colorschemes.nightfox = {
    enable = true;
    flavor = "duskfox";
  };
  highlightOverride.Whitespace.link = "LineNr";

  opts = {
    termguicolors = true;

    hidden = true;
    encoding = "utf-8";
    cursorline = true;
    guicursor = let blink-pattern = "blinkwait1-blinkoff500-blinkon500"; in [
      "n-v-c:block-${blink-pattern}"
      "i-ci:ver25-${blink-pattern}"
      "r-cr:hor20-${blink-pattern}"
    ];

    colorcolumn = "100," + (lib.concatStringsSep "," (lib.map builtins.toString (lib.range 120 499)));
    wrap = false;
    sidescroll = 8;
    showbreak = "↪";

    viewoptions = [ "folds" "cursor" ];

    tabstop = 4;
    shiftwidth = 4;
    expandtab = true;
    smartindent = true;

    foldmethod = "expr";
    foldexpr = "v:lua.vim.treesitter.foldexpr()";
    foldcolumn = "1";
    foldlevel = 99;
    foldlevelstart = 99;
    foldenable = true;

    ruler = true;
    number = true;
    signcolumn = "yes";

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
    listchars = {
      tab = "» ";
      trail = "·";
      nbsp = "⎵";
      precedes = "<";
      extends = ">";
    };
  };

  plugins = {
    bufferline.enable = true;
    copilot-lua.enable = true;
    dap.enable = true;
    dap-ui.enable = true;
    dap-virtual-text.enable = true;
    fzf-lua = {
      enable = true;
      keymaps = {
        "<c-t>" = "treesitter";
        "<c-o>" = "files";
        "<c-p>" = "buffers";
        "<c-r>" = "live_grep_resume";
      };
      # Change the default behaviour on multiple selectinos from opening a buffer list to opening
      # the files directly.
      settings.actions.files.__raw = ''{ ["enter"] = require("fzf-lua").actions.file_edit }'';
    };
    gitsigns.enable = true;
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
    none-ls = {
      enable = true;
      sources.diagnostics.statix.enable = true;
    };
    nvim-autopairs.enable = true;
    nvim-surround.enable = true;
    statuscol = {
      enable = true;
      settings.segments = [
        { text = [ "%=%{v:lnum} " ]; } # line number
        { text = [ "%C" ]; click = "v:lua.ScFa"; } # fold
        { text = [ "%s" ]; } # signs
      ];
    };
    treesitter.enable = true;
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
          "copilot"
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
      gitlab_ci_ls.enable = true;
      jsonls.enable = true;
      just.enable = true;
      lua_ls.enable = true;
      pyright.enable = true;
      ruff.enable = true;
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

  diagnostic.settings = {
    # disables diagnostics at the end of the lines.
    virtual_text = false;
    # enables diagnostics between lines.
    virtual_lines = true;
  };

  extraPlugins = with pkgs.vimPlugins; [
    vim-bufkill
    vim-just

    file-line
    nerdcommenter
    tabular
  ];

  globals.mapleader = ",";
  keymaps = [
    # improve the paste command 
    { mode = "x"; key = "p"; action = "pgvy"; options.desc = "re-yank what was pasted."; }

    # resolve conflicts with fzf-lua
    { mode = "n"; key = "<s-U>"; action = "<C-R>"; options.desc = "Redo an undo 😮"; }
    { mode = "n"; key = "gp"; action = "<C-O>"; options.desc = "Goto the previous cursor positions."; }

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

    { key = "."; action = ":"; }
    { key = ":"; action = "."; }
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    # bépo remapped
    { key = "«"; action = "<"; }
    { key = "»"; action = ">"; }
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
