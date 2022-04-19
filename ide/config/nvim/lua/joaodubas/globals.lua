-- based on tj code available in:
-- https://github.com/tjdevries/config_manager/blob/5d7d5b98fccd069829606464e65603017822cd72/xdg_config/nvim/lua/tj/globals.lua

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
