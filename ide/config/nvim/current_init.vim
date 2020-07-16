" vim: set foldmethod=marker foldlevel=0 nomodeline:

" general config based in:
" https://github.com/erkrnt/awesome-streamerrc/blob/ae1ec599c81b1bc68a4f9bd21c5c62bf4405f315/ThePrimeagen/init.vim
" fzf based in:
" https://dev.to/iggredible/how-to-search-faster-in-vim-with-fzf-vim-36ko
" coc based in:
" https://octetz.com/posts/vim-as-go-ide
" elixir-lsp based in:
" https://bernheisel.com/blog/vim-elixir-ls-plug/

" basic setup {{{
syntax on
set guicursor=
set number relativenumber
set hidden
set noerrorbells
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set smartindent
set nu
set nowrap
set noswapfile
set nobackup
set undodir=~/.config/nvim/undodir
set undofile
set noshowmatch
set nohlsearch
set incsearch
set termguicolors
set scrolloff=4
set noshowmode
set cmdheight=2
set updatetime=300
set shortmess+=c
set signcolumn=yes
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=1
" }}}

" plugin setup {{{
call plug#begin(stdpath('config') . '/plugged')
" autocomplete/lsp
Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next', 'do': 'bash install.sh' }
" editor
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-fugitive'
" navigation
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" colorscheme
Plug 'NLKNguyen/papercolor-theme'
Plug 'vim-airline/vim-airline'
call plug#end()
" }}}

" lsp setup {{{
let g:LanguageClient_serverCommands = {
    \ 'javascript': ['node', stdpath('config') . '/../lsp/js/javascript-typescript-langserver/lib/language-server-stdio'],
    \ 'elixir': ['/bin/bash', '-c', stdpath('config') . '/../lsp/elixir/_release/language_server.sh'],
    \ 'go': ['/bin/bash', '-c', stdpath('config') . '/../lsp/go/gopls'],
    \ 'terraform': ['/bin/bash', '-c', stdpath('config') . '/../lsp/terraform/terraform-ls'],
    \ }

nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
" }}}

" file navigation {{{
nnoremap <silent> <C-f> :Files<CR>
nnoremap <silent> <Leader>f :Rg<CR>
set grepprg=rg\ --vimgrep\ --smart-case\ --follow
" }}}

" colorscheme {{{
set t_Co=256
set background=dark
colorscheme PaperColor
" }}}
