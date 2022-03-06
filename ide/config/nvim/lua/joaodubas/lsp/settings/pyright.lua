local M = {}

local status_ok, job = pcall(require, "plenary.job")
if not status_ok then
  return M
end

local function poetry(args)
  local output
  local p = job:new({
    command = "poetry",
    args = args,
  })
  p:after_success(function(j)
    output = j:result()
  end)
  p:sync()
  return output or {}
end

local function python_path()
  local output = poetry({ "env", "info", "-p" })
  for _, value in pairs(output) do
    return value ~= nil and vim.fn.trim(value) .. "/bin/python3" or "python"
  end
end

M.settings = function()
  local path = python_path()
  return {
    settings = {
      pyright = {
        disableLanguageServices = false,
        disableOrganizeImports = false,
      },
      python = {
        analysis = {
          autoImportCompletions = true,
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          diagnosticSeverityOverrides = nil,
          extraPaths = nil,
          logLevel = "Information",
          stubPath = "typings",
          typeCheckingMode = "basic",
          typeshedPaths = nil,
          useLibraryCodeForTypes = false,
        },
        pythonPath = path,
        venvPath = "",
        venv = "",
      },
    }
  }
end

return M
