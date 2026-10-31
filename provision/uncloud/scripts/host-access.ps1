<#
.SYNOPSIS
    Configures or cleans up Windows host routing, split-DNS (NRPT), and Root CA trust
    for the Uncloud WSL2 lab (provision/uncloud).
.DESCRIPTION
    When the Uncloud lab runs inside WSL2, the libvirt bridge network (10.240.0.0/24)
    and Technitium DNS server (10.240.0.1) live inside the WSL2 VM. This script:
      1. Imports/Removes Caddy's internal Root CA in Cert:\CurrentUser\Root (no Admin needed).
      2. Adds/Removes a Windows NRPT split-DNS rule for `.internal` -> 10.240.0.1 (requires Admin).
      3. Adds/Removes a Windows IPv4 route to 10.240.0.0/24 via the WSL2 IP (requires Admin).
.PARAMETER Action
    "Up" to configure host access, or "Down" to remove it.
.PARAMETER WslIp
    Optional WSL2 IPv4 address. If omitted, queried automatically via `wsl.exe hostname -I`.
.PARAMETER SubnetCidr
    The Uncloud bridge network CIDR. Defaults to "10.240.0.0/24".
.PARAMETER DnsIp
    The Technitium DNS Server IP. Defaults to "10.240.0.1".
.PARAMETER DomainSuffix
    The internal DNS namespace suffix. Defaults to ".internal".
.EXAMPLE
    .\scripts\host-access.ps1 -Action Up
.EXAMPLE
    .\scripts\host-access.ps1 -Action Down
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("Up", "Down")]
    [string]$Action,

    [string]$WslIp = "",
    [string]$SubnetCidr = "10.240.0.0/24",
    [string]$DnsIp = "10.240.0.1",
    [string]$DomainSuffix = ".internal"
)

$ErrorActionPreference = "Stop"
$LabDir = Split-Path -Parent $PSScriptRoot
$RootCaPath = Join-Path -Path $LabDir -ChildPath ".cache\caddy-uncloud-root.crt"
$NrptComment = "UncloudLabInternal"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-DetectedWslIp {
    if (-not [string]::IsNullOrWhiteSpace($WslIp)) {
        return $WslIp.Trim()
    }
    $raw = (& wsl.exe hostname -I 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($raw)) {
        throw "Could not detect WSL2 IP via 'wsl.exe hostname -I'. Pass -WslIp explicitly."
    }
    return ($raw.Trim() -split '\s+')[0]
}

if ($Action -eq "Up") {
    # 1. Import Caddy Root CA into Cert:\CurrentUser\Root (works without elevation)
    if (Test-Path $RootCaPath) {
        Write-Host ">> Importing Caddy internal Root CA into Cert:\CurrentUser\Root ..."
        Import-Certificate -FilePath $RootCaPath -CertStoreLocation "Cert:\CurrentUser\Root" | Out-Null
    } else {
        Write-Warning "Root CA file not found at $RootCaPath (skipping certificate import)."
    }

    if (-not (Test-IsAdmin)) {
        Write-Warning "Administrator privileges are required to configure the Windows NRPT DNS rule and network route."
        Write-Host "Run the following in an elevated PowerShell prompt:" -ForegroundColor Yellow
        Write-Host "  pwsh -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action Up" -ForegroundColor Cyan
        exit 1
    }

    # 2. Configure Windows NRPT rule for .internal -> 10.240.0.1
    Write-Host ">> Configuring Windows NRPT split-DNS rule for $DomainSuffix -> $DnsIp ..."
    Get-DnsClientNrptRule | Where-Object { $_.Comment -eq $NrptComment -or $_.Namespace -contains $DomainSuffix } | Remove-DnsClientNrptRule -Force -ErrorAction SilentlyContinue
    Add-DnsClientNrptRule -Namespace $DomainSuffix -NameServers $DnsIp -Comment $NrptComment

    # 3. Configure static route to 10.240.0.0/24 via WSL2 IP
    $targetWslIp = Get-DetectedWslIp
    $subnetPrefix = ($SubnetCidr -split '/')[0]
    Write-Host ">> Configuring Windows route for $SubnetCidr via WSL2 IP $targetWslIp ..."
    & route.exe delete $subnetPrefix 2>$null | Out-Null
    & route.exe add $subnetPrefix mask 255.255.255.0 $targetWslIp metric 1 | Out-Null

    Clear-DnsClientCache
    Write-Host ">> Windows host access configured! You can now browse https://whoami.internal and http://dns.internal:5380" -ForegroundColor Green
}
elseif ($Action -eq "Down") {
    # 1. Remove Caddy Local Authority certs from Cert:\CurrentUser\Root
    Write-Host ">> Removing Caddy Local Authority certificate(s) from Cert:\CurrentUser\Root ..."
    Get-ChildItem -Path "Cert:\CurrentUser\Root" |
        Where-Object { $_.Subject -match "Caddy Local Authority" } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    if (-not (Test-IsAdmin)) {
        Write-Warning "Administrator privileges are required to remove the Windows NRPT DNS rule and network route."
        Write-Host "Run the following in an elevated PowerShell prompt:" -ForegroundColor Yellow
        Write-Host "  pwsh -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action Down" -ForegroundColor Cyan
        exit 1
    }

    # 2. Remove NRPT rule
    Write-Host ">> Removing Windows NRPT rule for $DomainSuffix ..."
    Get-DnsClientNrptRule | Where-Object { $_.Comment -eq $NrptComment -or $_.Namespace -contains $DomainSuffix } | Remove-DnsClientNrptRule -Force -ErrorAction SilentlyContinue

    # 3. Remove route
    $subnetPrefix = ($SubnetCidr -split '/')[0]
    Write-Host ">> Removing Windows route for $SubnetCidr ..."
    & route.exe delete $subnetPrefix 2>$null | Out-Null

    Clear-DnsClientCache
    Write-Host ">> Windows host access cleaned up." -ForegroundColor Green
}
