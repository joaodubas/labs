Invoke-Expression (&starship init powershell)
$Env:KOMOREBI_CONFIG_HOME = 'C:\Users\Administrator\.config\komorebi'
$Env:WHKD_CONFIG_HOME = 'C:\Users\Administrator\.config\whkd'
(&mise activate pwsh) | Out-String | Invoke-Expression
