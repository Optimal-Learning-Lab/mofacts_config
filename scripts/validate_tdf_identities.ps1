param(
    [string]$SchemaPath = 'C:\dev\MoFaCTS\mofacts\public\tdfSchema.json'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'tdf-identity-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$errors = [System.Collections.Generic.List[string]]::new()
$ids = @{}
$manifestPaths = @{}

foreach ($entry in $manifest.tdfs) {
    $relativePath = [string]$entry.path
    $manifestPaths[$relativePath.ToLowerInvariant()] = $true
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("Manifest TDF is missing: $relativePath")
        continue
    }

    $raw = Get-Content -LiteralPath $path -Raw
    $tdf = $raw | ConvertFrom-Json
    if (-not ($raw | Test-Json -SchemaFile $SchemaPath -ErrorAction SilentlyContinue)) {
        $errors.Add("TDF schema validation failed: $relativePath")
    }
    if ([string]$tdf.tdfId -ne [string]$entry.tdfId) {
        $errors.Add("Manifest ID does not match TDF: $relativePath")
    }
    $idKey = ([string]$tdf.tdfId).ToLowerInvariant()
    if ($ids.ContainsKey($idKey)) {
        $errors.Add("Duplicate TDF ID $($tdf.tdfId): $($ids[$idKey]) and $relativePath")
    } else {
        $ids[$idKey] = $relativePath
    }

    $directory = Split-Path -Parent $path
    $filesByName = @{}
    Get-ChildItem -LiteralPath $directory -File | ForEach-Object {
        $filesByName[$_.Name.ToLowerInvariant()] = $_.FullName
    }
    $stimulusFile = [string]$tdf.tutor.setspec.stimulusfile
    if (-not $stimulusFile -or -not $filesByName.ContainsKey($stimulusFile.ToLowerInvariant())) {
        $errors.Add("Missing package-local stimulus $stimulusFile for $relativePath")
    }

    $conditions = @($tdf.tutor.setspec.condition | Where-Object { $_ -is [string] -and $_.Trim() })
    $conditionIds = @($tdf.tutor.setspec.conditionTdfIds | Where-Object { $_ -is [string] -and $_.Trim() })
    if ($conditions.Count -ne $conditionIds.Count) {
        $errors.Add("Condition filename/ID count mismatch: $relativePath")
        continue
    }
    for ($index = 0; $index -lt $conditions.Count; $index += 1) {
        $conditionName = [string]$conditions[$index]
        $conditionKey = $conditionName.ToLowerInvariant()
        if (-not $filesByName.ContainsKey($conditionKey)) {
            $errors.Add("Missing package-local condition $conditionName for $relativePath")
            continue
        }
        $conditionTdf = Get-Content -LiteralPath $filesByName[$conditionKey] -Raw | ConvertFrom-Json
        if ([string]$conditionTdf.tdfId -ne [string]$conditionIds[$index]) {
            $errors.Add("Condition ID mismatch for $conditionName in $relativePath")
        }
    }
}

$excludedPrefixes = @($manifest.exclusions | ForEach-Object { ([string]$_.path).TrimEnd('\', '/').ToLowerInvariant() + '\' })
Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.json' -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($repoRoot.Length + 1)
    $relativeKey = $relativePath.ToLowerInvariant()
    if ($relativeKey -eq 'tdf-identity-manifest.json' -or ($excludedPrefixes | Where-Object { $relativeKey.StartsWith($_) })) {
        return
    }
    try { $json = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json } catch { return }
    if ($json.tutor -and $json.tutor.setspec -and -not $manifestPaths.ContainsKey($relativeKey)) {
        $errors.Add("Supported TDF is missing from the identity manifest: $relativePath")
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$demoPackages = @(
    @{ Folder = 'Public Demo Student Maps'; Zip = 'Public Demo Student Maps.zip' },
    @{ Folder = 'Public Demo Teacher AutoTutor'; Zip = 'Public Demo Teacher AutoTutor.zip' },
    @{ Folder = 'Public Demo Researcher 2x2'; Zip = 'Public Demo Researcher 2x2.zip' }
)
foreach ($package in $demoPackages) {
    $sourceFiles = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot $package.Folder) -File)
    $archive = [IO.Compression.ZipFile]::OpenRead((Join-Path $repoRoot $package.Zip))
    try {
        $entries = @($archive.Entries | Where-Object { -not $_.FullName.EndsWith('/') })
        $duplicates = @($entries | Group-Object { $_.FullName.ToLowerInvariant() } | Where-Object Count -gt 1)
        if ($duplicates.Count -gt 0) {
            $errors.Add("Case-insensitive duplicate entries in $($package.Zip)")
        }
        if ($entries.Count -ne $sourceFiles.Count) {
            $errors.Add("ZIP/source entry count mismatch in $($package.Zip)")
        }
        foreach ($source in $sourceFiles) {
            $matches = @($entries | Where-Object { $_.FullName.Equals($source.Name, [StringComparison]::OrdinalIgnoreCase) })
            if ($matches.Count -ne 1) {
                $errors.Add("ZIP entry missing or ambiguous for $($source.Name) in $($package.Zip)")
                continue
            }
            $sourceHash = (Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash
            $sha = [Security.Cryptography.SHA256]::Create()
            $stream = $matches[0].Open()
            try { $entryHash = [Convert]::ToHexString($sha.ComputeHash($stream)) } finally { $stream.Dispose(); $sha.Dispose() }
            if ($sourceHash -ne $entryHash) {
                $errors.Add("ZIP entry differs from source: $($package.Zip) / $($source.Name)")
            }
        }
    } finally {
        $archive.Dispose()
    }
}

$studentStimulus = Get-Content -LiteralPath (Join-Path $repoRoot 'Public Demo Student Maps\Wiki_World_Maps_top200_2025.json') -Raw
$studentMaps = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'Public Demo Student Maps') -Filter '*.webp' -File)
if ($studentMaps.Count -ne 200 -or $studentStimulus -notmatch 'Wikimedia Commons') {
    $errors.Add('Student demo must contain 200 attributed Wikimedia WebP maps.')
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

[pscustomobject]@{
    manifestTdfs = $manifest.tdfs.Count
    uniqueTdfIds = $ids.Count
    demoPackages = $demoPackages.Count
    studentMaps = $studentMaps.Count
} | Format-List
