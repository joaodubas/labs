" vim: set foldmethod=marker foldlevel=0 nomodeline:

" setup lsp {{{
lua << EOF
local xdg_config_home = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
local config_dir = xdg_config_home .. "/nvim/plugged"

local lsp_status = require('lsp-status')
local completion = require('completion')
local lsp        = require('lspconfig')

local on_attach = function(client, bufnr)
  lsp_status.on_attach(client, bufnr)
  completion.on_attach(client, bufnr)
end

lsp_status.register_progress()
lsp_status.config({
  status_symbol = '',
  indicator_errors = 'e',
  indicator_warnings = 'w',
  indicator_info = 'i',
  indicator_hint = 'h',
  indicator_ok = 'ok',
})

lsp.elixirls.setup{
  cmd = { config_dir .. "/elixir-ls/release/language_server.sh" },
  on_attach = on_attach,
  capabilities = lsp_status.capabilities
}

lsp.terraformls.setup{
  on_attach = on_attach,
  capabilities = lsp_status.capabilities
}

lsp.tsserver.setup{
  on_attach = on_attach,
  capabilities = lsp_status.capabilities
}
EOF
" }}}

" configure lsp {{{
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
" }}}

" configure completion {{{
set completeopt=menuone,noinsert,noselect
let g:completion_enable_auto_popup = 0
let g:completion_matching_strategy_list = ['exact', 'substring', 'fuzzy']
inoremap <silent><expr> <c-p> completion#trigger_completion()
" }}}

" configure diagnostic {{{
let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_auto_popup_while_jump = 1
" }}}
