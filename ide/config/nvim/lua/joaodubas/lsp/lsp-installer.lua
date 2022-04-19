local status_ok, lsp_installer = pcall(require, "nvim-lsp-installer")
if not status_ok then
  return
end

-- Register a handler that will be called for all installed server.
lsp_installer.on_server_ready(function(server)
  local opts = {
    on_attach = require("joaodubas.lsp.handlers").on_attach,
    capabilities = require("joaodubas.lsp.handlers").capabilities,
  }

  local server_opts = { }
  if server.name == "jsonls" then
    server_opts = require("joaodubas.lsp.settings.jsonls")
  elseif server.name == "sumneko_lua" then
    server_opts = require("joaodubas.lsp.settings.sumneko_lua")
  elseif server.name == "elixirls" then
    server_opts = require("joaodubas.lsp.settings.elixirls")
  elseif server.name == "pyright" then
    server_opts = require("joaodubas.lsp.settings.pyright").settings()
  end

  opts = vim.tbl_deep_extend("force", server_opts, opts)

  server:setup(opts)
end)
