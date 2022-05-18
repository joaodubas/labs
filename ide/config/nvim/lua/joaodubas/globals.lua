-- based on tj code available in:
-- https://github.com/tjdevries/config_manager/blob/5d7d5b98fccd069829606464e65603017822cd72/xdg_config/nvim/lua/tj/globals.lua
job = require("plenary.job")

CMD = function(cmd, args)
  local output
  local p = job:new({
    command = cmd,
    args = args,
    on_exit = function(j, r)
      output = r == 0 and j:result() or {}
      print(vim.inspect(output))
    end,
  })
  p:sync()
  return output
end

P = function(v)
  print(vim.inspect(v))
  return v
end

RELOAD = function(...)
  return require("plenary.reload").reload_module(...)
end

R = function(name)
  RELOAD(name)
  return require(name)
end
