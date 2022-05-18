local M = {}

local status_ok, job = pcall(require, "plenary.job")
if not status_ok then
  return M
end

local function command(cmd, args)
  local output
  local p = job:new({
    command = cmd,
    args = args,
  })
  p:after_success(function(j)
    output = j:result()
  end)
  p:sync()
  return output or {}
end

local function poetry(args)
  return command("poetry", args)
end

local function pyenv(args)
  return command("pyenv", args)
end

local function poetry_path()
  local output = poetry({ "env", "info", "-p" })
  for _, value in pairs(output) do
    return value ~= nil and vim.fn.trim(value) .. "/bin/python3" or nil
  end
end

local function pyenv_path()
  local output = pyenv({ "which", "python" })
  for _, value in pairs(output) do
    return value ~= nil and vim.fn.trim(value) or nil
  end
end

local function python_path()
  return poetry_path() or pyenv_path() or "python"
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
