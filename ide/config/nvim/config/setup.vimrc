" vim: set foldmethod=maker foldlevel=0 nomodeline:

" plugin setup {{{
call plug#begin()
" autocomplete/lsp
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" editor
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-fugitive'
" languages
" Plug 'fatih/vim-go'
" Plug 'elixir-editors/vim-elixir'
" Plug 'slashmili/alchemist.vim'
" navigation
Plug '~/.fzf'
Plug 'junegunn/fzf.vim'
" coloscheme
Plug 'drewtempelmeyer/palenight.vim'
Plug 'vim-airline/vim-airline'
call plug#end()
" }}}

" file navigation {{{
nnoremap <silent> <C-f> :Files<CR>
nnoremap <silent> <Leader>f :Rg<CR>
set grepprg=rg\ --vimgrep\ --smart-case\ --follow
" }}}

" colorscheme {{{
set t_Co=256
set background=dark
colorscheme palenight
" }}}
