[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$modFolderName = 'PZPulseExpanded'
$workshopRoot = Join-Path $env:USERPROFILE 'Zomboid\Workshop\PZ-Pulse-Expanded'
$workshopContents = Join-Path $workshopRoot "Contents\mods\$modFolderName"
$payloadFolders = @('42', 'common')

$running = Get-Process -Name 'ProjectZomboid64', 'ProjectZomboid32', 'ProjectZomboid' -ErrorAction SilentlyContinue
if ($running) {
    throw 'Project Zomboid is running. Close it before publishing Workshop staging files.'
}

$modInfo = Join-Path $repoRoot '42\mod.info'
if (-not (Test-Path -LiteralPath $modInfo -PathType Leaf)) {
    throw "Repository mod source is missing: $modInfo"
}

foreach ($requiredMetadata in @('workshop.txt', 'preview.png')) {
    $metadataPath = Join-Path $repoRoot $requiredMetadata
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        throw "Repository Workshop metadata is missing: $metadataPath"
    }
}

$workshopText = Get-Content -LiteralPath (Join-Path $repoRoot 'workshop.txt')
$idLines = @($workshopText | Where-Object { $_ -match '^id=' })
if ($idLines.Count -gt 1 -or ($idLines.Count -eq 1 -and $idLines[0] -notmatch '^id=[1-9][0-9]*$')) {
    throw 'workshop.txt must omit id= for a first publish, or contain one non-zero numeric Workshop item ID.'
}

Add-Type -AssemblyName System.Drawing
$previewPath = Join-Path $repoRoot 'preview.png'
$preview = [Drawing.Image]::FromFile($previewPath)
try {
    if ($preview.RawFormat.Guid -ne [Drawing.Imaging.ImageFormat]::Png.Guid -or $preview.Width -ne 512 -or $preview.Height -ne 512) {
        throw 'preview.png must be a 512x512 PNG.'
    }
}
finally {
    $preview.Dispose()
}

New-Item -ItemType Directory -Path $workshopContents -Force | Out-Null

$sourceFiles = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($folderName in $payloadFolders) {
    $sourceFolder = Join-Path $repoRoot $folderName
    if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) {
        continue
    }

    $destinationFolder = Join-Path $workshopContents $folderName
    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
    Copy-Item -Path (Join-Path $sourceFolder '*') -Destination $destinationFolder -Recurse -Force

    Get-ChildItem -LiteralPath $sourceFolder -Recurse -File | ForEach-Object {
        $relativeInsideFolder = $_.FullName.Substring($sourceFolder.Length).TrimStart('\')
        $relative = Join-Path $folderName $relativeInsideFolder
        $sourceFiles[$relative] = $_.FullName
    }
}

$resolvedStaging = [IO.Path]::GetFullPath($workshopContents).TrimEnd('\')
$stagingPrefix = $resolvedStaging + '\'

# Copy-Item does not remove files retired from the source payload. Delete only
# destination-only files whose normalized paths remain inside this staging mod.
Get-ChildItem -LiteralPath $resolvedStaging -Recurse -File | ForEach-Object {
    $candidate = [IO.Path]::GetFullPath($_.FullName)
    $relative = $candidate.Substring($resolvedStaging.Length).TrimStart('\')
    if (-not $sourceFiles.ContainsKey($relative)) {
        if (-not $candidate.StartsWith($stagingPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove a file outside Workshop staging: $candidate"
        }
        Remove-Item -LiteralPath $candidate -Force
    }
}

Get-ChildItem -LiteralPath $resolvedStaging -Recurse -Directory |
    Sort-Object { $_.FullName.Length } -Descending |
    Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) } |
    Remove-Item -Force

foreach ($metadata in @('workshop.txt', 'preview.png')) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $metadata) -Destination (Join-Path $workshopRoot $metadata) -Force
}

$missing = [Collections.Generic.List[string]]::new()
$different = [Collections.Generic.List[string]]::new()
foreach ($entry in $sourceFiles.GetEnumerator()) {
    $stagedPath = Join-Path $resolvedStaging $entry.Key
    if (-not (Test-Path -LiteralPath $stagedPath -PathType Leaf)) {
        $missing.Add($entry.Key)
        continue
    }

    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.Value).Hash
    $stagedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $stagedPath).Hash
    if ($sourceHash -ne $stagedHash) {
        $different.Add($entry.Key)
    }
}

$extra = @(Get-ChildItem -LiteralPath $resolvedStaging -Recurse -File | Where-Object {
    $relative = $_.FullName.Substring($resolvedStaging.Length).TrimStart('\')
    -not $sourceFiles.ContainsKey($relative)
})

if ($missing.Count -or $different.Count -or $extra.Count) {
    throw "Workshop staging verification failed. Missing=$($missing.Count); Different=$($different.Count); Extra=$($extra.Count)"
}

Write-Output "Published repository mod to: $workshopContents"
Write-Output "Verified files: $($sourceFiles.Count)"
if ($idLines.Count -eq 0) {
    Write-Output 'First-publish mode: workshop.txt has no id= line. Add the assigned Steam Workshop ID after the first successful upload.'
}
