# New MOFaCTS System Creation Guide

This guide describes the workflow used to create new content systems such as `wiki world maps` and `A&P Openstax Chapter 1 Terms`.

Use it when starting a new tutor from web content, image assets, textbook terms, CSV data, or another structured source.

## Goal

A new MOFaCTS content system usually needs:

- A folder in this config repository.
- A TDF JSON file that describes the lesson, instructions, and stimulus file.
- A stimulus JSON file that contains the cards/items.
- Optional source CSV or audit files so the system can be checked and regenerated.
- Optional script files in `scripts/` when the source can be fetched or transformed programmatically.

## Repository Choice

Use this repo for content work:

```powershell
C:\Users\ppavl\OneDrive\Active projects\mofacts_config
```

Use the app repo only when the runtime behavior needs to change:

```powershell
C:\dev\mofacts\svelte-app\mofacts
```

Examples of app behavior changes include image sizing, answer matching, speech recognition behavior, TDF parsing, or UI rendering. If TypeScript app code changes, run the full app typecheck from `C:\dev\mofacts\svelte-app\mofacts`:

```powershell
npm run typecheck
```

## Recommended Folder Layout

Create one folder per system:

```text
mofacts_config/
  A&P Openstax Chapter 1 Terms/
    A&P Openstax Chapter 1 Terms_TDF.json
    A&P_Openstax_Chapter_1_Terms_stims.json
    A_P_Openstax_Chapter_1_Terms_source_terms.csv

  wiki world maps/
    Wiki World Maps_TDF.json
    Wiki_World_Maps_top200_2025.json
    Wiki World Maps URL Map.csv

  scripts/
    generate_openstax_key_terms_tutor.ps1

  audit_reports/
    commons_top200_locator_audit.ps1
```

Put generated lesson files in the lesson folder. Put reusable generators in `scripts/`. Put one-off audits or lookup reports in `audit_reports/` when they may be useful again.

## Step 1: Define The System

Before writing files, decide:

- System name shown to learners, for example `A&P Openstax Chapter 1 Terms`.
- Folder name, usually the same as the system name.
- TDF filename, usually `{System Name}_TDF.json`.
- Stimulus filename, usually a safe filename with spaces replaced by underscores.
- Source type, such as textbook terms, map images, vocabulary rows, or figures.
- Learner task, such as "identify the term from the definition" or "name the highlighted country".
- Attribution and licensing text.

Keep names exact. The `stimulusfile` value inside the TDF must match the stimulus JSON filename.

## Step 2: Gather Source Data

For a web source, first confirm that the data is actually present and stable enough to fetch.

Good source checks:

- The page has a repeated structure, such as OpenStax key terms in `<dl><dt>term</dt><dd>definition</dd></dl>`.
- The image files have predictable names or can be found through an API/search query.
- The content license allows reuse.
- The source can be credited in the learner instructions.

For OpenStax key terms, use the reusable generator script:

```powershell
Set-Location "C:\Users\ppavl\OneDrive\Active projects\mofacts_config"

.\scripts\generate_openstax_key_terms_tutor.ps1 `
  -Url "https://openstax.org/books/anatomy-and-physiology-2e/pages/1-key-terms" `
  -LessonName "A&P Openstax Chapter 1 Terms" `
  -OutputDir ".\A&P Openstax Chapter 1 Terms" `
  -ChapterLabel "Chapter 1" `
  -BookTitle "Anatomy and Physiology 2e"
```

For Wikimedia map tutors, the useful pattern is:

```text
https://commons.wikimedia.org/wiki/Special:Redirect/file/{FileName}.svg
```

Example:

```text
https://commons.wikimedia.org/wiki/Special:Redirect/file/Afghanistan_in_its_region.svg
```

Using URLs in `imgSrc` is usually enough. The original SVG files do not need to be downloaded unless offline packaging or local editing is required.

## Step 3: Design The Stimulus File

The stimulus file contains the actual learning items. The top-level structure should be simple and predictable.

Example image card:

```json
{
  "setspec": {
    "lessonname": "Wiki World Maps",
    "clusters": [
      {
        "clusterid": 0,
        "clustername": "Afghanistan",
        "stims": [
          {
            "stimulusid": 0,
            "display": {
              "type": "image",
              "imgSrc": "https://commons.wikimedia.org/wiki/Special:Redirect/file/Afghanistan_in_its_region.svg",
              "alt": "Locator map for Afghanistan",
              "attribution": {
                "creatorName": "TUBS",
                "sourceName": "Wikimedia Commons",
                "sourceUrl": "https://commons.wikimedia.org/wiki/File:Afghanistan_in_its_region.svg",
                "licenseName": "CC BY-SA 3.0",
                "licenseUrl": "https://creativecommons.org/licenses/by-sa/3.0/"
              }
            },
            "response": {
              "correctResponse": "Afghanistan"
            }
          }
        ]
      }
    ]
  }
}
```

For licensed media prompts, keep attribution in `display.attribution`. The app renders a small linked caption under the prompt image using `creatorName`, `sourceName`, and `licenseName`, and opens `sourceUrl` when clicked.

Example definition card:

```json
{
  "setspec": {
    "lessonname": "A&P Openstax Chapter 1 Terms",
    "clusters": [
      {
        "clusterid": 0,
        "clustername": "anatomy",
        "stims": [
          {
            "stimulusid": 0,
            "display": {
              "type": "text",
              "text": "science that studies the form and composition of the body's structures"
            },
            "response": {
              "correctResponse": "anatomy"
            }
          }
        ]
      }
    ]
  }
}
```

Design rules:

- Use one cluster per answer unless there is a strong reason to group multiple cards.
- Keep `clusterid` values contiguous, starting at `0`.
- Keep `stimulusid` values predictable, usually matching the cluster id for one-card clusters.
- Put the learner-facing prompt in `display`.
- Put the exact answer in `response.correctResponse`.
- Include `alt` text for image cards.
- Keep a source CSV when data came from scraping or a lookup script.

## Step 4: Design The TDF File

The TDF connects the lesson metadata, instructions, stimulus file, and cluster list.

Common fields to verify:

- `tutor.setspec.lessonname` matches the system name.
- `tutor.setspec.stimulusfile` matches the stimulus JSON filename exactly.
- `tutor.setspec.shuffleclusters` is set intentionally.
- `tutor.setspec.unit[0].unitinstructions` explains the task and credits the source.
- `tutor.setspec.unit[0].clusterlist` includes every cluster id in the stimulus file.
- UI settings match the content type, such as larger image display for maps.

Instructions should be learner-friendly:

- Explain what the learner will see.
- Explain what they should type or say.
- Mention accepted answer style if relevant.
- Credit the content source and license after the task description.

Example instruction pattern:

```text
You will see a definition from OpenStax Anatomy and Physiology 2e, Chapter 1. Type or say the key term that best matches the definition.

Content is adapted from OpenStax Anatomy and Physiology 2e, Chapter 1 Key Terms, licensed under Creative Commons Attribution 4.0.
```

## Step 5: Write JSON Without A BOM

MOFaCTS upload can fail if JSON files start with a UTF-8 byte order mark. The upload error may look like this:

```text
Unexpected token '﻿', "﻿{ "t"... is not valid JSON
```

Write files as UTF-8 without BOM. In PowerShell 7+, this is the default for `Set-Content -Encoding utf8`. When in doubt, explicitly validate the first bytes.

Check first bytes:

```powershell
$path = ".\A&P Openstax Chapter 1 Terms\A&P Openstax Chapter 1 Terms_TDF.json"
[System.BitConverter]::ToString([System.IO.File]::ReadAllBytes($path)[0..2])
```

Good starts usually look like:

```text
7B-0D-0A
7B-0A-20
```

Bad BOM start:

```text
EF-BB-BF
```

Remove a BOM if needed:

```powershell
$path = ".\A&P Openstax Chapter 1 Terms\A&P Openstax Chapter 1 Terms_TDF.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$text = [System.IO.File]::ReadAllText($path)
[System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
```

## Step 6: Validate The Files

Run these checks before uploading or zipping.

Parse JSON:

```powershell
Get-Content ".\A&P Openstax Chapter 1 Terms\A&P Openstax Chapter 1 Terms_TDF.json" -Raw | ConvertFrom-Json | Out-Null
Get-Content ".\A&P Openstax Chapter 1 Terms\A&P_Openstax_Chapter_1_Terms_stims.json" -Raw | ConvertFrom-Json | Out-Null
```

Check for mojibake or replacement characters:

```powershell
Select-String -Path ".\A&P Openstax Chapter 1 Terms\*.json" -Pattern "â|Ã|�|﻿"
```

Check the stimulus filename referenced by the TDF:

```powershell
$tdfPath = ".\A&P Openstax Chapter 1 Terms\A&P Openstax Chapter 1 Terms_TDF.json"
$tdf = Get-Content $tdfPath -Raw | ConvertFrom-Json
$stimFile = $tdf.tutor.setspec.stimulusfile
Test-Path (Join-Path (Split-Path $tdfPath) $stimFile)
```

Check cluster counts:

```powershell
$stimPath = ".\A&P Openstax Chapter 1 Terms\A&P_Openstax_Chapter_1_Terms_stims.json"
$stim = Get-Content $stimPath -Raw | ConvertFrom-Json
$clusters = @($stim.setspec.clusters)
$clusters.Count
$clusters.clusterid | Sort-Object | Select-Object -First 5
$clusters.clusterid | Sort-Object | Select-Object -Last 5
```

For URL-based image systems, sample several URLs in a browser or with PowerShell:

```powershell
Invoke-WebRequest "https://commons.wikimedia.org/wiki/Special:Redirect/file/Afghanistan_in_its_region.svg" -Method Head
```

## Step 7: Review A Few Cards Manually

Always inspect samples before considering the system done.

Review:

- First card.
- Last card.
- A few items with punctuation, accents, abbreviations, or multi-word answers.
- A few image cards with unusually large or small source SVGs.
- The title and instructions in the learner UI, if possible.

For speech or typed answers, pay attention to short words and terms with sounds speech recognition may drop. The `growth` issue was an example where the target answer was correct but speech recognition could plausibly return `grow`.

## Step 8: Package If Needed

If the workflow needs a zip file, zip the lesson folder after validation:

```powershell
Compress-Archive `
  -Path ".\A&P Openstax Chapter 1 Terms\*" `
  -DestinationPath ".\A&P Openstax Chapter 1 Terms.zip" `
  -Force
```

Do not zip before checking JSON parsing, BOMs, stimulus filename references, and source text encoding.

## Step 9: Preserve The Recipe

For every new system, leave behind enough information to regenerate or audit it.

Good artifacts:

- Source CSV with original terms, answers, source URLs, or resolved image URLs.
- Generator script if the workflow is reusable.
- Audit report if the source data required matching, search, aliases, or manual decisions.
- Notes in the TDF instructions identifying source and license.

This is especially important when the source contains 50+ items or when matching requires country names, aliases, title-case fixes, punctuation handling, or external URLs.

## Quick Checklist

Before calling a new system complete:

- The lesson has its own folder.
- The TDF file parses as JSON.
- The stimulus file parses as JSON.
- Both JSON files are UTF-8 without BOM.
- The TDF `stimulusfile` matches the real stimulus filename.
- Cluster ids are contiguous and included in the TDF cluster list.
- The instructions explain the task clearly.
- The instructions credit the source and license.
- A few representative cards have been manually checked.
- Source CSV, script, or audit artifacts are saved when useful.
- If app code changed, `npm run typecheck` passed in the app repo.
