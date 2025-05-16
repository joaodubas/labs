<#
.SYNOPSIS
    Deploys common Windows configuration files to their standard locations.
.DESCRIPTION
    This script moves specified configuration files for PowerShell, Wezterm, and WSL
    to their respective user profile directories. It can also perform a dry run
    to show what actions would be taken without actually modifying the file system.
.PARAMETER DryRun
    If specified, the script will output the actions it would perform without
    actually creating directories or moving files.
.EXAMPLE
    .\deploy_configs.ps1
    Deploys all configuration files.
.EXAMPLE
    .\deploy_configs.ps1 -DryRun
    Shows what actions would be taken without making any changes.
#>
[CmdletBinding()]
param (
    [switch]$DryRun
)

# Script to deploy common Windows configuration files

# --- PowerShell Profile & Config ---
$psProfileDir = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\PowerShell"
$psProfileSourceFile = "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$psProfileDestFile = Join-Path -Path $psProfileDir -ChildPath "Microsoft.PowerShell_profile.ps1"
$psConfigSourceFile = "Documents\PowerShell\powershell.config.json"
$psConfigDestFile = Join-Path -Path $psProfileDir -ChildPath "powershell.config.json"

# --- Wezterm Config ---
$weztermConfigDir = Join-Path -Path $env:USERPROFILE -ChildPath ".config\wezterm"
$weztermSourceFile = "config\wezterm\wezterm.lua"
$weztermDestFile = Join-Path -Path $weztermConfigDir -ChildPath "wezterm.lua"

# --- WSL Config ---
$wslSourceFile = "wslconfig"
$wslDestFile = Join-Path -Path $env:USERPROFILE -ChildPath ".wslconfig"

# Function to ensure directory exists and move file
function Move-ConfigFile {
    param (
        [string]$SourceFile,
        [string]$DestinationFile,
        [string]$DestinationDir,
        [switch]$IsDryRun
    )

    if (-not (Test-Path $DestinationDir)) {
        if ($IsDryRun) {
            Write-Host "DRY RUN: Would create directory: $DestinationDir"
        } else {
            Write-Host "Creating directory: $DestinationDir"
            New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
        }
    }

    if (Test-Path $SourceFile) {
        if ($IsDryRun) {
            Write-Host "DRY RUN: Would move $SourceFile to $DestinationFile"
        } else {
            Write-Host "Moving $SourceFile to $DestinationFile..."
            Move-Item -Path $SourceFile -Destination $DestinationFile -Force
        }
    } else {
        Write-Warning "Source file not found: $SourceFile"
    }
}

if ($DryRun) {
    Write-Host "*** Performing a DRY RUN. No actual file changes will be made. ***" -ForegroundColor Yellow
    Write-Host ""
}

# Deploy PowerShell files
Write-Host "--- Deploying PowerShell configuration ---"
Move-ConfigFile -SourceFile $psProfileSourceFile -DestinationFile $psProfileDestFile -DestinationDir $psProfileDir -IsDryRun:$DryRun
Move-ConfigFile -SourceFile $psConfigSourceFile -DestinationFile $psConfigDestFile -DestinationDir $psProfileDir -IsDryRun:$DryRun
Write-Host "To verify PowerShell profile location, you can run: Split-Path \$PROFILE.CurrentUserCurrentHost"
Write-Host ""

# Deploy Wezterm config
Write-Host "--- Deploying Wezterm configuration ---"
Move-ConfigFile -SourceFile $weztermSourceFile -DestinationFile $weztermDestFile -DestinationDir $weztermConfigDir -IsDryRun:$DryRun
Write-Host "Remember to set WEZTERM_CONFIG_DIR and WEZTERM_CONFIG_FILE environment variables if needed."
Write-Host "WEZTERM_CONFIG_DIR: $weztermConfigDir"
Write-Host "WEZTERM_CONFIG_FILE: $weztermDestFile"
Write-Host ""

# Deploy WSL config
Write-Host "--- Deploying WSL configuration ---"
if (Test-Path $wslSourceFile) {
    if ($DryRun) {
        Write-Host "DRY RUN: Would move $wslSourceFile to $wslDestFile"
    } else {
        Write-Host "Moving $wslSourceFile to $wslDestFile..."
        Move-Item -Path $wslSourceFile -Destination $wslDestFile -Force
    }
} else {
    Write-Warning "Source file not found: $wslSourceFile"
}
Write-Host ""

Write-Host "--- Winget Package Installation ---"
Write-Host "For winget packages, run the following command in PowerShell:"
Write-Host "winget import -i winget.json"
Write-Host ""

Write-Host "Script execution finished."
