#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$WinRARLicensePath,
    [switch]$FromLocalPackage
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ($PSVersionTable.PSEdition -ne 'Desktop' -or -not [Environment]::Is64BitProcess) {
    throw 'Run this in 64-bit Windows PowerShell 5.1.'
}
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Open Windows PowerShell as Administrator, then run the installer again.'
}

# Licences never pass through GitHub or the download manifest.
if (-not $WinRARLicensePath) {
    $candidates = @()
    if ($PSScriptRoot) { $candidates += Join-Path $PSScriptRoot 'rarreg.key' }
    $desktop = [Environment]::GetFolderPath('Desktop')
    if ($desktop) { $candidates += Join-Path $desktop 'rarreg.key' }
    $WinRARLicensePath = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}
if ($WinRARLicensePath) {
    $WinRARLicensePath = (Resolve-Path -LiteralPath $WinRARLicensePath -ErrorAction Stop).ProviderPath
}

$stage = Join-Path $env:TEMP ('WindowsServerSetup-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage -Force | Out-Null
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if ($FromLocalPackage) {
        if (-not $PSScriptRoot) { throw 'Run install.ps1 from the extracted package for local installation.' }
        $manifestPath = Join-Path $PSScriptRoot 'manifest.json'
    } else {
        # Resolve main once so the manifest and scripts come from the same immutable commit.
        $headers = @{ 'User-Agent' = 'windows-server-setup'; 'Accept' = 'application/vnd.github+json' }
        $commit = Invoke-RestMethod -Uri 'https://api.github.com/repos/waqaarhussain/windows-server-setup/commits/main' -Headers $headers
        $revision = [string]$commit.sha
        if ($revision -notmatch '^[a-f0-9]{40}$') { throw 'GitHub did not return a valid source commit.' }
        $baseUrl = "https://raw.githubusercontent.com/waqaarhussain/windows-server-setup/$revision"
        Write-Host "Source commit: $revision" -ForegroundColor Cyan
        $manifestPath = Join-Path $stage 'manifest.json'
        Invoke-WebRequest -Uri "$baseUrl/manifest.json" -UseBasicParsing -OutFile $manifestPath
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1) { throw 'Unsupported installer manifest.' }
    $files = @(
        'scripts/Setup-WindowsServer.ps1',
        'scripts/Disable-CustomLayout.ps1',
        'scripts/Configure-Extras.ps1',
        'scripts/Invoke-StorageCleanup.ps1',
        'scripts/Restore-OptionalServices.ps1'
    )
    foreach ($relative in $files) {
        $expected = [string]$manifest.files.$relative
        if ($expected -notmatch '^[a-fA-F0-9]{64}$') { throw "Missing or invalid checksum: $relative" }
        $destination = Join-Path $stage $relative
        New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
        if ($FromLocalPackage) {
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot $relative) -Destination $destination
        } else {
            Invoke-WebRequest -Uri "$baseUrl/$relative" -UseBasicParsing -OutFile $destination
        }
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $expected) {
            throw "Checksum mismatch: $relative. No setup script was run."
        }
    }

    $restoreDir = Join-Path $env:ProgramData 'WindowsVPSSetup'
    New-Item -ItemType Directory -Path $restoreDir -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $stage 'scripts/Disable-CustomLayout.ps1') -Destination $restoreDir -Force
    foreach ($helper in @('Configure-Extras.ps1','Restore-OptionalServices.ps1')) {
        Copy-Item -LiteralPath (Join-Path $stage "scripts/$helper") -Destination $restoreDir -Force
    }
    $setupArgs = @{}
    if ($WinRARLicensePath) { $setupArgs.WinRARLicensePath = $WinRARLicensePath }
    & (Join-Path $stage 'scripts/Setup-WindowsServer.ps1') @setupArgs
} finally {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
