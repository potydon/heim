#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$packagesFile = join-path $PSScriptRoot 'packages.txt'
$ids = get-content $packagesFile |
    foreach-object { $_.trim() } |
    where-object { $_ -and -not $_.startswith('#') }

$exportFile = join-path $env:TEMP 'winget-installed.json'
winget export -o $exportFile --accept-source-agreements | out-null

$export = get-content $exportFile -raw | convertfrom-json
$installed = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]($export.Sources.Packages.PackageIdentifier),
    [System.StringComparer]::OrdinalIgnoreCase
)

$flags = @(
    '--exact'
    '--silent'
    '--accept-package-agreements'
    '--accept-source-agreements'
    '--disable-interactivity'
)

$failed = @()
foreach ($id in $ids) {
    if ($installed.contains($id)) {
        write-host "[skip] $id" -foregroundColor darkGray
        continue
    }

    $source = if ($id -match '^[A-Z0-9]{12}$') { 'msstore' } else { 'winget' }

    write-host "[install] $id ($source)" -foregroundColor cyan
    winget install --id $id -s $source @flags

    if ($LASTEXITCODE -ne 0) { $failed += $id }
}

if ($failed) {
    write-host "`nFailed:" -foregroundColor red
    $failed | foreach-object { write-host "  $_" }
}
