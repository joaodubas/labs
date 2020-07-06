" fzf based in:
" https://dev.to/iggredible/how-to-search-faster-in-vim-with-fzf-vim-36ko
" coc based in:
" https://octetz.com/posts/vim-as-go-ide
" elixir-lsp based in:
" https://bernheisel.com/blog/vim-elixir-ls-plug/

call plug#begin()
" autocomplete/lsp
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'elixir-lsp/elixir-ls', { 'do': { -> g:ElixirLS.compile() } }
" editor
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-fugitive'
" navigation
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
" colorscheme
Plug 'NLKNguyen/papercolor-theme'
Plug 'vim-airline/vim-airline'
call plug#end()

""" elixir-ls start
let g:ElixirLS = {}
let g:ElixirLS.path = stdpath('config') . '/plugged/elixir-ls'
let g:ElixirLS.lsp = ElixirLS.path . '/release/language_server.sh'
let g:ElixirLS.cmd = join([
	\ 'asdf install &&',
	\ 'mix do',
	\ 'local.hex --force --if-missing,',
	\ 'local.rebar --force,',
	\ 'deps.get,',
	\ 'compile,',
	\ 'elixir_ls.release'
	\ ], ' ')

function ElixirLS.on_stdout(_job_id, data, _event)
	let self.output[-1] .= a:data[0]
	call extend(self.output, a:data[1:])
endfunction

let g:ElixirLS.on_stderr = function(ElixirLS.on_stdout)

function ElixirLS.on_exit(_job_id, exitcode, _event)
	if a:exitcode == 0
		echom '>>> ElixirLS compiled'
	else
		echoerr join(self.output, ' ')
		echoerr '>>> ElixirLS compilation failed'
	endif
endfunction

function ElixirLS.compile()
	let me = copy(g:ElixirLS)
	let me.output = ['']
	echom '>>> ElixirLS compilation started'
	let me.id = jobstart('cd ' . me.path . ' && git pull && ' . me.cmd, me)
endfunction

" update elixir language server
call coc#config('elixir', {
	\ 'command': g:ElixirLS.lsp,
	\ 'filetypes': ['elixir', 'eelixir']
	\ })
call coc#config('elixir.pathToElixirLS', g:ElixirLS.lsp)
""" elixir-ls end

""" coc start
let g:coc_global_extensions = [
	\ 'coc-json',
	\ 'coc-yaml',
	\ 'coc-marketplace',
	\ 'coc-python',
	\ 'coc-elixir',
	\ 'coc-go',
	\ 'coc-diagnostic'
	\ ]
set hidden          " if hidden is not set, TextEdit might fail
set cmdheight=2     " better display for messages
set updatetime=300  " smaller update time for CursorHold & CursorHoldI
set shortmess+=c    " don't give |ins-completion-menu| messages
set signcolumn=yes  " always show signcolumns

" use tab to trigger completion with characters ahead and navigate
" use command ':verbose imap <tab>' to ensure tab is not mapped by other
" plugins
inoremap <silent><expr> <TAB>
	\ pumvisible() ? "\<C-n>" :
	\ <SID>check_back_space() ?  "\<TAB>" :
	\ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1] =~# '\s'
endfunction

" use <c-space> to trigger completion
inoremap <silent><expr> <c-space> coc#refresh()
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
""" coc end

""" navigation start
nnoremap <silent> <C-f> :Files<CR>
nnoremap <silent> <Leader>f :Rg<CR>
set grepprg=rg\ --vimgrep\ --smart-case\ --follow
""" navigation end

""" editor start
set foldmethod=indent
set foldnestmax=10
set nofoldenable
set foldlevel=1
set number relativenumber
""" editor end

""" colorscheme start
set t_Co=256
set background=dark
colorscheme PaperColor
""" colorscheme end

""" syntax highlight start
syntax on
""" syntax highlight end
