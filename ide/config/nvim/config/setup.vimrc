" vim: set foldmethod=marker foldlevel=0 nomodeline:

" plugin setup {{{
call plug#begin()
" autocomplete/lsp
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'nvim-lua/lsp-status.nvim'
Plug 'elixir-lsp/elixir-ls', {'do': { -> g:ElixirLS.compile() }}
Plug 'fatih/vim-go', {'do': ':GoUpdateBinaries'}
" editor
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-fugitive'
" navigation
Plug 'junegunn/fzf', {'do': { -> fzf#install() }}
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

" elixir-ls setup {{{
" based on: https://bernheisel.com/blog/vim-elixir-ls-plug/
let g:ElixirLS = {}
let ElixirLS.path = stdpath('config') . '/plugged/elixir-ls'
let ElixirLS.lsp = ElixirLS.path . '/release/language_server.sh'
let ElixirLS.cmd = join([
    \ 'cp .release-tool-versions .tool-versions',
    \ '&& asdf install',
    \ '&& mix do',
    \ 'local.hex --force --if-missing,',
    \ 'local.rebar --force,',
    \ 'clean,',
    \ 'deps.clean --all,',
    \ 'deps.get,',
    \ 'compile,',
    \ 'elixir_ls.release',
    \ '&& rm .tool-versions'
    \ ], ' ')

function ElixirLS.on_stdout(_job_id, data, _event)
    let self.output[-1] .= a:data[0]
    call extend(self.output, a:data[1:])
endfunction

let ElixirLS.on_stderr = function(ElixirLS.on_stdout)

function ElixirLS.on_exit(_job_id, exitcode, _event)
    if a:exitcode[0] == 0
        echom '>>> ElixirLS compiled'
    else
        echoerr join(self.output, ' ')
        echoerr '>>> ElixirLS compilation failed'
    endif
endfunction

function ElixirLS.compile()
    let me = copy(g:ElixirLS)
    let me.output = ['']
    echom '>>> compiling ElixirLS'
    let me.id = jobstart('cd ' . me.path . ' && git pull && ' . me.cmd, me)
endfunction
" }}}
