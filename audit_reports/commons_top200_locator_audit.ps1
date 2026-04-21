param(
  [string]$Top200Path = 'C:\Users\ppavl\OneDrive\Active projects\mofacts_config\Countries of the World\Countries_of_the_World_top200_2025.json',
  [string]$OutputJson = 'C:\Users\ppavl\OneDrive\Active projects\mofacts_config\audit_reports\commons_top200_locator_map_report.json',
  [string]$OutputCsv = 'C:\Users\ppavl\OneDrive\Active projects\mofacts_config\audit_reports\commons_top200_locator_map_report.csv',
  [string]$OutputMd = 'C:\Users\ppavl\OneDrive\Active projects\mofacts_config\audit_reports\commons_top200_locator_map_report.md'
)

$ErrorActionPreference = 'Stop'

$apiBase = 'https://commons.wikimedia.org/w/api.php'
$userAgent = 'MoFaCTS-Codex/1.0 (commons locator map audit; contact via local workspace)'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8NoBom {
  param(
    [string]$Path,
    [string]$Content
  )

  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Invoke-CommonsQuery {
  param(
    [hashtable]$Query
  )

  $pairs = foreach ($key in $Query.Keys) {
    '{0}={1}' -f [uri]::EscapeDataString([string]$key), [uri]::EscapeDataString([string]$Query[$key])
  }
  $uri = '{0}?{1}' -f $apiBase, ($pairs -join '&')
  Start-Sleep -Milliseconds 250
  return Invoke-RestMethod -Uri $uri -UserAgent $userAgent -Headers @{ 'Api-User-Agent' = $userAgent } -TimeoutSec 30
}

function Split-Batches {
  param(
    [object[]]$Items,
    [int]$Size
  )

  for ($index = 0; $index -lt $Items.Count; $index += $Size) {
    ,$Items[$index..([Math]::Min($index + $Size - 1, $Items.Count - 1))]
  }
}

function Get-TitleCandidate {
  param(
    [string]$Name
  )

  return 'File:{0} in its region.svg' -f $Name
}

function Get-AliasCandidates {
  param(
    [string]$Name
  )

  $aliasMap = @{
    'DR Congo' = @(
      'File:Democratic Republic of the Congo in its region.svg',
      'File:Congo-Kinshasa in its region.svg'
    )
    'Republic of the Congo' = @(
      'File:Republic of the Congo in its region.svg',
      'File:Congo-Brazzaville in its region.svg'
    )
    'Ivory Coast' = @(
      "File:Cote d'Ivoire in its region.svg",
      'File:Côte d''Ivoire in its region.svg'
    )
    'Cape Verde' = @(
      'File:Cape Verde in its region.svg',
      'File:Cabo Verde in its region.svg'
    )
    'Myanmar' = @(
      'File:Myanmar in its region.svg',
      'File:Burma in its region.svg'
    )
    'Gambia' = @(
      'File:Gambia in its region.svg',
      'File:The Gambia in its region.svg'
    )
    'South Korea' = @(
      'File:South Korea in its region.svg',
      'File:Republic of Korea in its region.svg'
    )
    'North Korea' = @(
      'File:North Korea in its region.svg',
      'File:Democratic People''s Republic of Korea in its region.svg'
    )
    'Russia' = @(
      'File:Russia in its region.svg',
      'File:Russian Federation in its region.svg'
    )
    'Palestine' = @(
      'File:Palestine in its region.svg',
      'File:State of Palestine in its region.svg',
      'File:West Bank in its region.svg'
    )
    'Czech Republic' = @(
      'File:Czech Republic in its region.svg',
      'File:Czechia in its region.svg'
    )
    'East Timor / Timor-Leste' = @(
      'File:Timor-Leste in its region.svg',
      'File:East Timor in its region.svg'
    )
  }

  if ($aliasMap.ContainsKey($Name)) {
    return $aliasMap[$Name]
  }

  return @()
}

function Get-SearchNames {
  param(
    [string]$Name
  )

  $searchMap = @{
    'DR Congo' = @('DR Congo', 'Democratic Republic of the Congo', 'Congo-Kinshasa')
    'Republic of the Congo' = @('Republic of the Congo', 'Congo-Brazzaville')
    'Ivory Coast' = @('Ivory Coast', "Cote d'Ivoire", 'Côte d''Ivoire')
    'Cape Verde' = @('Cape Verde', 'Cabo Verde')
    'Gambia' = @('Gambia', 'The Gambia')
    'Czechia' = @('Czechia', 'Czech Republic')
    'North Macedonia' = @('North Macedonia', 'Macedonia')
    'Timor-Leste' = @('Timor-Leste', 'East Timor')
    'Palestine' = @('Palestine', 'State of Palestine', 'West Bank')
  }

  if ($searchMap.ContainsKey($Name)) {
    return $searchMap[$Name]
  }

  return @($Name)
}

function Resolve-ByTitles {
  param(
    [object[]]$Entries,
    [scriptblock]$TitleSelector,
    [string]$MatchType
  )

  $pending = @()
  foreach ($entry in $Entries) {
    $titles = @(& $TitleSelector $entry)
    foreach ($title in $titles) {
      if ([string]::IsNullOrWhiteSpace($title)) {
        continue
      }
      $pending += [pscustomobject]@{
        Name = $entry.Name
        LocalImg = $entry.LocalImg
        Title = $title
      }
    }
  }

  if ($pending.Count -eq 0) {
    return @()
  }

  $resolved = @()
  foreach ($batch in Split-Batches -Items $pending -Size 50) {
    $titleString = ($batch | ForEach-Object { $_.Title }) -join '|'
    $response = Invoke-CommonsQuery @{
      action = 'query'
      format = 'json'
      prop = 'imageinfo'
      iiprop = 'url|mime|size'
      titles = $titleString
    }

    $pageIndex = @{}
    foreach ($pageProperty in $response.query.pages.PSObject.Properties) {
      $page = $pageProperty.Value
      $pageIndex[$page.title] = $page
    }

    foreach ($candidate in $batch) {
      if (-not $pageIndex.ContainsKey($candidate.Title)) {
        continue
      }

      $page = $pageIndex[$candidate.Title]
      if ($page.missing -or -not $page.imageinfo) {
        continue
      }

      $imageInfo = $page.imageinfo[0]
      $resolved += [pscustomobject]@{
        Name = $candidate.Name
        LocalImg = $candidate.LocalImg
        MatchType = $MatchType
        CommonsTitle = $page.title
        CommonsUrl = $imageInfo.url
        Mime = $imageInfo.mime
        Width = $imageInfo.width
        Height = $imageInfo.height
      }
    }
  }

  return $resolved
}

function Search-CommonsTitle {
  param(
    [string]$Name
  )

  $variantPreference = @(
    '',
    ' (undisputed)',
    ' (whole)',
    ' (mainland)',
    ' (de-facto)',
    ' (claimed)',
    ' (disputed)',
    ' (claimed hatched)',
    ' (disputed hatched)',
    ' (claimed and disputed hatched)'
  )

  $bestTitle = $null
  $bestScore = -1

  foreach ($searchName in Get-SearchNames -Name $Name) {
    $searchTerms = @(
      ('"{0} in its region"' -f $searchName),
      ('"{0}" "in its region"' -f $searchName)
    )

    foreach ($term in $searchTerms) {
      $response = Invoke-CommonsQuery @{
        action = 'query'
        format = 'json'
        list = 'search'
        srnamespace = '6'
        srlimit = '10'
        srsearch = $term
      }

      foreach ($hit in @($response.query.search)) {
        if ($hit.title -notlike 'File:*in its region*.svg') {
          continue
        }

        $score = 0
        $exactBase = 'File:{0} in its region.svg' -f $searchName
        if ($hit.title -eq $exactBase) {
          $score = 1000
        }
        else {
          for ($i = 0; $i -lt $variantPreference.Count; $i++) {
            $candidate = 'File:{0} in its region{1}.svg' -f $searchName, $variantPreference[$i]
            if ($hit.title -eq $candidate) {
              $score = 900 - ($i * 10)
              break
            }
          }
        }

        if ($score -eq 0 -and $hit.title -like ('File:{0} in its region*.svg' -f $searchName)) {
          $score = 700
        }

        if ($score -gt $bestScore) {
          $bestScore = $score
          $bestTitle = $hit.title
        }
      }
    }
  }

  return $bestTitle
}

$top200Raw = Get-Content -Path $Top200Path -Raw | ConvertFrom-Json
$top200Entries = @(
  $top200Raw.setspec.clusters | ForEach-Object {
    [pscustomobject]@{
      Name = $_.stims[0].response.correctResponse
      LocalImg = $_.stims[0].display.imgSrc
    }
  }
)

$exactMatches = Resolve-ByTitles -Entries $top200Entries -TitleSelector { param($entry) Get-TitleCandidate -Name $entry.Name } -MatchType 'exact'
$resolvedByName = @{}
foreach ($row in $exactMatches) {
  if (-not $resolvedByName.ContainsKey($row.Name)) {
    $resolvedByName[$row.Name] = $row
  }
}

$remainingForAlias = @($top200Entries | Where-Object { -not $resolvedByName.ContainsKey($_.Name) })
$aliasMatches = Resolve-ByTitles -Entries $remainingForAlias -TitleSelector { param($entry) Get-AliasCandidates -Name $entry.Name } -MatchType 'alias'
foreach ($row in $aliasMatches) {
  if (-not $resolvedByName.ContainsKey($row.Name)) {
    $resolvedByName[$row.Name] = $row
  }
}

$remainingForSearch = @($top200Entries | Where-Object { -not $resolvedByName.ContainsKey($_.Name) })
$searchMatches = @()
foreach ($entry in $remainingForSearch) {
  $searchTitle = Search-CommonsTitle -Name $entry.Name
  if (-not $searchTitle) {
    continue
  }

  $resolved = @(Resolve-ByTitles -Entries @($entry) -TitleSelector { param($innerEntry) $searchTitle } -MatchType 'search')
  if ($resolved.Count -gt 0 -and -not $resolvedByName.ContainsKey($entry.Name)) {
    $searchMatches += $resolved[0]
    $resolvedByName[$entry.Name] = $resolved[0]
  }
}

$finalRows = foreach ($entry in $top200Entries) {
  if ($resolvedByName.ContainsKey($entry.Name)) {
    $resolvedByName[$entry.Name]
  }
  else {
    [pscustomobject]@{
      Name = $entry.Name
      LocalImg = $entry.LocalImg
      MatchType = 'missing'
      CommonsTitle = $null
      CommonsUrl = $null
      Mime = $null
      Width = $null
      Height = $null
    }
  }
}

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('o')
  sourceStimulusFile = $Top200Path
  totals = [pscustomobject]@{
    total = $finalRows.Count
    exact = @($finalRows | Where-Object MatchType -eq 'exact').Count
    alias = @($finalRows | Where-Object MatchType -eq 'alias').Count
    search = @($finalRows | Where-Object MatchType -eq 'search').Count
    missing = @($finalRows | Where-Object MatchType -eq 'missing').Count
  }
  rows = $finalRows
}

$summaryJson = $summary | ConvertTo-Json -Depth 6
Write-Utf8NoBom -Path $OutputJson -Content $summaryJson
$finalRows | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

$mdLines = @()
$mdLines += '# Commons Top-200 Locator Map Report'
$mdLines += ''
$mdLines += ('Generated: `{0}`' -f $summary.generatedAt)
$mdLines += ''
$mdLines += ('Source stimulus file: `{0}`' -f $summary.sourceStimulusFile)
$mdLines += ''
$mdLines += '## Summary'
$mdLines += ''
$mdLines += ('- Total rows: {0}' -f $summary.totals.total)
$mdLines += ('- Exact title matches: {0}' -f $summary.totals.exact)
$mdLines += ('- Alias-title matches: {0}' -f $summary.totals.alias)
$mdLines += ('- Search-discovered matches: {0}' -f $summary.totals.search)
$mdLines += ('- Missing: {0}' -f $summary.totals.missing)
$mdLines += ''
$mdLines += '## Missing'
$mdLines += ''
$missingRows = @($finalRows | Where-Object MatchType -eq 'missing')
if ($missingRows.Count -eq 0) {
  $mdLines += '- None'
}
else {
  foreach ($row in $missingRows) {
    $mdLines += ('- {0} ({1})' -f $row.Name, $row.LocalImg)
  }
}
$mdLines += ''
$mdLines += '## Resolved Rows'
$mdLines += ''
$mdLines += '| Name | Local Img | Match | Commons Title | Commons URL |'
$mdLines += '| --- | --- | --- | --- | --- |'
foreach ($row in $finalRows) {
  $title = if ($row.CommonsTitle) { $row.CommonsTitle } else { '' }
  $url = if ($row.CommonsUrl) { $row.CommonsUrl } else { '' }
  $mdLines += ('| {0} | {1} | {2} | {3} | {4} |' -f $row.Name, $row.LocalImg, $row.MatchType, $title, $url)
}

Write-Utf8NoBom -Path $OutputMd -Content ($mdLines -join [Environment]::NewLine)

Write-Output ('JSON report: {0}' -f $OutputJson)
Write-Output ('CSV report: {0}' -f $OutputCsv)
Write-Output ('Markdown report: {0}' -f $OutputMd)
Write-Output ('Summary: total={0}, exact={1}, alias={2}, search={3}, missing={4}' -f $summary.totals.total, $summary.totals.exact, $summary.totals.alias, $summary.totals.search, $summary.totals.missing)
