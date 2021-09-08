set nocompatible

call plug#begin(stdpath('data') . 'plugged')

" buffer mgmt & file navigation
Plug 'qpkorr/vim-bufkill'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'lotabout/skim'
Plug 'bogado/file-line'

" coding tools
Plug 'LunarWatcher/auto-pairs', { 'tags': '*' }
Plug 'tpope/vim-surround'
Plug 'scrooloose/nerdcommenter'

" just
Plug 'NoahTheDuke/vim-just'

" rust
Plug 'cespare/vim-toml'
Plug 'neoclide/coc.nvim', {'branch':'release'}

" git
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'

" markdown
Plug 'plasticboy/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarnpkg install' }

" Table and code alignment
Plug 'godlygeek/tabular'
"Plug 'junegunn/vim-easy-align'

"
" debugging
" Plug 'vim-scripts/Conque-GDB'
" Plug 'phcerdan/Conque-GDB'
" Plug 'sakhnik/nvim-gdb', { 'do': ':!./install.sh \| UpdateRemotePlugins' }

" UI
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'Badacadabra/vim-archery'
Plug 'datsuns/vim-syntax-arm-objdump-d'

call plug#end()

syntax on
filetype plugin indent on

" enable all 24bit colors
set termguicolors
set hidden
set number
set relativenumber
set encoding=utf-8
set nowrap
set sidescroll=8
" set breakindent
" set breakindentopt=sbr
set showbreak=↪

" prevents from saving the pwd in the view file. This leads to pwd being
" different from pwd of the starting shell
set viewoptions-=curdir 

" tab and indentation management
set tabstop=4
set smartindent
set shiftwidth=4
set expandtab

set foldmethod=syntax " Fold on sytax
set foldcolumn=1 " Show the fold column
set foldlevel=99 " Level above will be folded by default

set smartcase
set ruler
set incsearch
set hlsearch

" set cscopetag
set mouse=a

colorscheme archery
"hi Normal guibg=NONE ctermbg=NONE

" enable per project vimrc
set exrc

" configure popup menu
set wildmenu
set wildmode=full
set wildignore+=*.a,*.o
set wildignore+=*.bmp,*.gif,*.ico,*.jpg,*.png
set wildignore+=.DS_Store,.git,.hg,.svn
set wildignore+=*~,*.swp,*.tmp

" show right margin
let &colorcolumn="100,".join(range(120, 999),",")

" Use a blinking upright bar cursor in Insert mode, a blinking block in normal
if &term == 'xterm-256color' || &term == 'screen-256color' || &term == 'rxvt-256color'
    let &t_SI = "\<Esc>[5 q" " blinking thin vertical bar in insert mode
    let &t_EI = "\<Esc>[1 q" " blinking block when ending insert mode
    let &t_SR = "\<Esc>[3 q" " blinking underline in replace mode
endif

" show trailing spaces and nbsp
set list listchars=tab:»\ ,trail:·,nbsp:⎵,precedes:<,extends:>

" ===============================================
" Coc recommended config

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved.
if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" =================================================================================================
" Plugins config

" ctrl-p
let g:ctrlp_types = ['buf', 'mru', 'fil']
let g:ctrlp_open_multiple_files = 'i'
let g:ctrlp_clear_cache_on_exit = 0

" airline related config
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#hunks#enabled = 1
let g:airline#extensions#coc#enabled = 1
let g:airline_theme = 'archery'
let g:airline_powerline_fonts = 1

" auto-pair
au FileType rust    let b:AutoPairs = autopairs#AutoPairsDefine({"r'": "'", "b'": "'", '::\zs<': '>'})
au FileType verilog let b:AutoPairs = autopairs#AutoPairsDefine({}, ["`"])

" coc
let g:coc_install_yarn_cmd = 'yarnpkg'

" coc-snippets
let g:coc_snippets_next = '<tab>'
let g:coc_snippets_prev = '<S-Tab>'

" nerdcommenter alignment
let g:NERDDefaultAlign = 'left'

" markdown preview
" keep updating the page after switch back and forth between buffers
let g:mkdp_auto_close = 0

" =================================================================================================
" Key map

let mapleader = ","

" bépo config
let s:uname = system("uname -s")
if s:uname != "Darwin\n"
    noremap « <
    noremap » >
    noremap . :
    noremap : .
endif

" coc
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" <Plug>(hello-world) is remapped to an actual command. you must not use
" noremap to map keys to them
"

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Remap keys for applying codeAction to the current buffer.
nmap <leader>ac  v<Plug>(coc-codeaction-selected)<C-C>
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Use CTRL-S for selections ranges.
" Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
nmap <silent> <C-s> <Plug>(coc-range-select)
xmap <silent> <C-s> <Plug>(coc-range-select)

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold   :call CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR     :call CocAction('runCommand', 'editor.action.organizeImport')

" confirm with enter & autoselect the first entry if none has been selected
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
"autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : <SID>check_back_space() ? "\<TAB>" : coc#refresh()
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" buffer navigation
map      <silent> <C-x>          <Plug>BufKillBangBd
if s:uname != "Darwin\n"
  nnoremap <silent> <C-S-Left>     :bp<CR>
  nnoremap <silent> <C-S-Right>    :bn<CR>
  inoremap <silent> <C-S-Left>     <Esc>:bp<CR>i
  inoremap <silent> <C-S-Right>    <Esc>:bn<CR>i
else
  nnoremap <silent> <D-S-Left>     :bp<CR>
  nnoremap <silent> <D-S-Right>    :bn<CR>
  inoremap <silent> <D-S-Left>     <Esc>:bp<CR>i
  inoremap <silent> <D-S-Right>    <Esc>:bn<CR>i
endif

nnoremap gp             <C-O>
noremap  <silent> <C-o>          :SK<CR>
inoremap <silent> <C-o>          <Esc>:SK<CR>

" smart home
noremap  <expr> <Home> (col('.') == matchend(getline('.'), '^\s*')+1 ? '0' : '^')
imap <silent> <Home> <Esc><right><Home>i

" re-yank what was pasted
xnoremap p pgvy

" =================================================================================================
" Auto run group config

" aug FixHiddenView
"     au!
"     au BufReadPost * setlocal buflisted
"     au BufReadPost * setlocal bufhidden=
" aug END

au BufNewFile,BufRead *.vh set syntax=verilog

" remove trailing spaces
aug ClearTrailing
    au!
    au BufWritePre *.py,*.c,*.h :%s/\s\+\n/\r/e
aug END

" enable these for md files only
aug MDSpellCheck
    au!
    au BufRead,BufNewFile *.md setlocal spell spelllang=en
    " au BufRead,BufNewFile *.md set wrap lbr
aug END

augroup RustFolds
  au!
  au BufWritePost,BufLeave,WinLeave *.rs mkview
  au BufRead *.rs silent! loadview
augroup END

" enter secure mode
set secure
