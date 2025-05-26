local wezterm = require('wezterm')

local powershell_path = 'C:/Users/Administrator/AppData/Local/Microsoft/WindowsApps/Microsoft.PowerShell_8wekyb3d8bbwe/pwsh.exe'

local powershell_args = { powershell_path, '-WorkingDirectory', '~' }

local ubuntu_args = { 'wsl.ex', '--distribution', 'Ubuntu', '--cd', '~' }

local launch_menu = {
  {
    label = 'PowerShell',
    args = powershell_args,
  },
  {
    label = 'Ubuntu',
    args = ubuntu_args,
  },
}

local config = wezterm.config_builder()

config.color_scheme = 'tokyonight'
config.default_prog = ubuntu_args
config.enable_tab_bar = true
config.font = wezterm.font_with_fallback({
  'GoMono Nerd Font Mono',
  'JetBrains Mono',
  'MonaspiceAr Nerd Font Propo',
  'FiraCode Nerd Font',
  'FiraMono Nerd Font',
  'FuraCode NF',
  'Pixel Code Light',
  'CozetteVector',
  'Consolas',
  'Courier New',
})
config.font_size = 10
config.keys = {
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.ShowLauncher },
}
config.launch_menu = launch_menu
config.window_close_confirmation = 'AlwaysPrompt'
config.window_decorations = 'RESIZE'

return config
