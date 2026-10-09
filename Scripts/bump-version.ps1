[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('patch', 'minor', 'major')]
    [string]$Bump,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Title,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Notes
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$utf8 = [Text.UTF8Encoding]::new($false)

function Read-Source([string]$relativePath) {
    $path = Join-Path $repoRoot $relativePath
    if (-not [IO.File]::Exists($path)) { throw "Missing release file: $path" }
    return [IO.File]::ReadAllText($path)
}

function Replace-Once([string]$content, [string]$pattern, [string]$replacement, [string]$label) {
    $matches = [regex]::Matches($content, $pattern, [Text.RegularExpressions.RegexOptions]::Multiline)
    if ($matches.Count -ne 1) { throw "Expected one $label marker; found $($matches.Count)." }
    return [regex]::Replace($content, $pattern, { param($match) $replacement }, [Text.RegularExpressions.RegexOptions]::Multiline)
}

$info = Read-Source '42/mod.info'
$versionMatches = [regex]::Matches($info, '^modversion=(\d+)\.(\d+)\.(\d+)$', [Text.RegularExpressions.RegexOptions]::Multiline)
if ($versionMatches.Count -ne 1) { throw 'Expected exactly one numeric modversion in mod.info.' }
$current = $versionMatches[0].Groups[0].Value.Substring('modversion='.Length)
$parts = @([int]$versionMatches[0].Groups[1].Value, [int]$versionMatches[0].Groups[2].Value, [int]$versionMatches[0].Groups[3].Value)
switch ($Bump) {
    'major' { $parts[0]++; $parts[1] = 0; $parts[2] = 0 }
    'minor' { $parts[1]++; $parts[2] = 0 }
    'patch' { $parts[2]++ }
}
$next = $parts -join '.'
$titleLine = ($Title -replace '\s+', ' ').Trim()
if (-not $titleLine -or $titleLine.Contains('[') -or $titleLine.Contains(']')) {
    throw 'Title must be nonempty plain text without BBCode brackets.'
}
$noteLines = @($Notes | ForEach-Object { ($_ -replace '\s+', ' ').Trim() })
if (@($noteLines | Where-Object { -not $_ -or $_ -match '[\[\]]' }).Count -gt 0) {
    throw 'Notes must be nonempty plain text without BBCode brackets.'
}

$collectorPath = '42/media/lua/client/PZPulseExpanded/PZ_Pulse_Expanded.lua'
$changelogPath = 'docs/steam-changelog.txt'
$collector = Read-Source $collectorPath
$changelog = Read-Source $changelogPath
if ($changelog -notmatch '^\[h1\]PZ Pulse Expanded - Changelog\[/h1\]\r?\n') {
    throw 'Unexpected Steam changelog heading.'
}

$updates = [ordered]@{}
$updates['42/mod.info'] = Replace-Once $info "^modversion=$([regex]::Escape($current))$" "modversion=$next" 'mod.info version'
$updates[$collectorPath] = Replace-Once $collector "^    version = `"$([regex]::Escape($current))`",$" "    version = `"$next`"," 'PZ Pulse registration version'
$newEntry = "[h2]Version $next - $titleLine[/h2]`n`n[list]`n" + (($noteLines | ForEach-Object { "[*]$_" }) -join "`n") + "`n[/list]`n`n[hr][/hr]`n`n"
$headingMatch = [regex]::Match($changelog, '^\[h1\]PZ Pulse Expanded - Changelog\[/h1\]\r?\n\r?\n')
if (-not $headingMatch.Success) { throw 'Missing Steam changelog insertion point.' }
$updates[$changelogPath] = $changelog.Insert($headingMatch.Length, $newEntry)

if ($PSCmdlet.ShouldProcess($repoRoot, "Bump PZ Pulse Expanded $current to $next")) {
    foreach ($relativePath in $updates.Keys) {
        [IO.File]::WriteAllText((Join-Path $repoRoot $relativePath), $updates[$relativePath], $utf8)
    }
    Write-Output "PZ Pulse Expanded: $current -> $next"
}
