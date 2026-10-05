[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$junction = Join-Path $env:USERPROFILE 'Zomboid\mods\PZPulseExpandedDev'
$devRoot = Join-Path $repoRoot ('artifacts\dev\local-junction-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fffffff'))
$modRoot = Join-Path $devRoot 'mods\PZPulseExpandedDev'

if (Test-Path -LiteralPath $junction) {
    $item = Get-Item -LiteralPath $junction -Force
    $allowedRoot = Join-Path $repoRoot 'artifacts\dev\local-junction-'
    if ($item.LinkType -ne 'Junction' -or -not $item.Target.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase) -or
        -not $item.Target.EndsWith('\mods\PZPulseExpandedDev', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove an unmanaged path: $junction"
    }
    Remove-Item -LiteralPath $junction
    Write-Output "DEV OFF: $junction"
    return
}

& (Join-Path $PSScriptRoot 'build-dev-bundle.ps1') -OutputRoot $devRoot
New-Item -ItemType Junction -Path $junction -Target $modRoot | Out-Null
Write-Output "DEV ON: $junction -> $modRoot (ID PZ_Pulse_Expanded_Dev)"
