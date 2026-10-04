[CmdletBinding()]
param(
    [string]$OutputRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) ("artifacts\dev\build-{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$devId = 'PZ_Pulse_Expanded_Dev'
$modFolder = 'PZPulseExpandedDev'
$resolvedOutput = [IO.Path]::GetFullPath($OutputRoot)
$repoPrefix = [IO.Path]::GetFullPath($repoRoot).TrimEnd('\') + '\'
$publicStaging = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE 'Zomboid\Workshop\PZ-Pulse-Expanded')).TrimEnd('\')

if (-not $resolvedOutput.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase) -or
    $resolvedOutput.StartsWith($publicStaging + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Development output must be inside this repository and outside public Workshop staging.'
}
if (Test-Path -LiteralPath $resolvedOutput) {
    throw "Output already exists; choose a fresh directory: $resolvedOutput"
}

$modRoot = Join-Path $resolvedOutput "mods\$modFolder"
New-Item -ItemType Directory -Path $modRoot -Force | Out-Null
foreach ($folder in @('42', 'common')) {
    $source = Join-Path $repoRoot $folder
    if (Test-Path -LiteralPath $source -PathType Container) {
        Copy-Item -LiteralPath $source -Destination $modRoot -Recurse
    }
}

$modInfo = Join-Path $modRoot '42\mod.info'
$collector = Join-Path $modRoot '42\media\lua\client\PZPulseExpanded\PZ_Pulse_Expanded.lua'
$infoText = [IO.File]::ReadAllText($modInfo)
$collectorText = [IO.File]::ReadAllText($collector)
if (([regex]::Matches($infoText, '(?m)^id=PZ_Pulse_Expanded$')).Count -ne 1 -or
    ([regex]::Matches($collectorText, 'mod = "PZ_Pulse_Expanded",')).Count -ne 1) {
    throw 'Expected public mod ID in mod.info and PZ Pulse registration exactly once.'
}
$infoText = [regex]::Replace($infoText, '(?m)^id=PZ_Pulse_Expanded$', "id=$devId")
$infoText = [regex]::Replace($infoText, '(?m)^name=PZ Pulse Expanded$', 'name=PZ Pulse Expanded (Dev)')
$collectorText = $collectorText.Replace('mod = "PZ_Pulse_Expanded",', "mod = `"$devId`",")
[IO.File]::WriteAllText($modInfo, $infoText, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($collector, $collectorText, [Text.UTF8Encoding]::new($false))

$zipPath = Join-Path $resolvedOutput 'PZPulseExpandedDev.zip'
Compress-Archive -LiteralPath (Join-Path $resolvedOutput 'mods') -DestinationPath $zipPath -CompressionLevel Optimal
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $entries = @($archive.Entries | ForEach-Object FullName)
    if (-not ($entries -contains "mods/$modFolder/42/mod.info") -or
        -not ($entries -contains "mods/$modFolder/42/media/lua/client/PZPulseExpanded/PZ_Pulse_Expanded.lua")) {
        throw 'Development archive is missing its mod metadata or collector.'
    }
}
finally {
    $archive.Dispose()
}

Write-Output "Development mod: $modRoot"
Write-Output "Development archive: $zipPath"
Write-Output "SHA-256: $((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash)"
Write-Output "Mod ID: $devId"
