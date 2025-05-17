# windows common configuration

To add the common configuration files in `Windows`, run the following command:

```powershell
.\install.ps1
```

If you want to see what would be made, pass `-DryRun` to the script:

```powershell
.\install.ps1 -DryRun
```

## `powershell` profile & config

The files `Microsoft.PowerShell_profile.ps1` and `powershell.config.json` control the presentation of `PowerShell`. They should be placed in `%USERPROFILE%\Documents\PowerShell`.

You can check the correct location by running:

```powershell
Split-Path $Profile.CurrentUserCurrentHost
```

## `wezterm` config

This file controls `wezterm` terminal emulator configuration and should be placed in `%USERPROFILE%\.config\wezterm\wezterm.lua`.

It's necessary to configure the following environment variables:

* `WEZTERM_CONFIG_DIR`: `%USERPROFILE%\.config\wezterm`
* `WEZTERM_CONFIG_FILE`: `%USERPROFILE%\.config\wezterm\wezterm.lua`

## `wsl` config

This file controls `wsl` configuration and should be placed in `%USERPROFILE%\.wslconfig`.

## `winget` install

This file controls `winget` package installation. To install the listed packges, run:

```powershell
winget import -i winget.json
```
