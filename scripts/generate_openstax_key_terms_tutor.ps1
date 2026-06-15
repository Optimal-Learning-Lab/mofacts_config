param(
  [Parameter(Mandatory = $true)]
  [string]$Url,

  [Parameter(Mandatory = $true)]
  [string]$LessonName,

  [Parameter(Mandatory = $true)]
  [string]$OutputDir,

  [string]$StimFileName,
  [string]$TdfFileName,
  [string]$ChapterLabel = 'Chapter',
  [string]$BookTitle = 'Anatomy and Physiology 2e'
)

$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$userAgent = 'MoFaCTS-OpenStax-KeyTerms/1.0 (local content generation)'

function Write-Utf8NoBom {
  param(
    [string]$Path,
    [string]$Content
  )

  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function ConvertTo-SafeFileBase {
  param(
    [string]$Value
  )

  $safe = $Value -replace '[^\w\-.]+', '_'
  $safe = $safe.Trim('_')
  if ([string]::IsNullOrWhiteSpace($safe)) {
    return 'openstax_key_terms'
  }
  return $safe
}

function ConvertFrom-HtmlText {
  param(
    [string]$Html
  )

  $withoutTags = $Html -replace '<[^>]+>', ' '
  $decoded = [System.Net.WebUtility]::HtmlDecode($withoutTags)
  $normalized = $decoded -replace '\s+', ' '
  return $normalized.Trim()
}

function Get-KeyTermsFromHtml {
  param(
    [string]$Html
  )

  $terms = @()
  $matches = [regex]::Matches(
    $Html,
    '<dl\b[^>]*>\s*<dt\b[^>]*>(?<term>.*?)</dt>\s*<dd\b[^>]*>(?<definition>.*?)</dd>\s*</dl>',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
      [System.Text.RegularExpressions.RegexOptions]::Singleline
  )

  foreach ($match in $matches) {
    $term = ConvertFrom-HtmlText $match.Groups['term'].Value
    $definition = ConvertFrom-HtmlText $match.Groups['definition'].Value
    if ([string]::IsNullOrWhiteSpace($term) -or [string]::IsNullOrWhiteSpace($definition)) {
      continue
    }

    $terms += [pscustomobject]@{
      term = $term
      definition = $definition
    }
  }

  return $terms
}

if ([string]::IsNullOrWhiteSpace($StimFileName)) {
  $StimFileName = '{0}_stims.json' -f (ConvertTo-SafeFileBase $LessonName)
}
if ([string]::IsNullOrWhiteSpace($TdfFileName)) {
  $TdfFileName = '{0}_TDF.json' -f $LessonName
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$response = Invoke-WebRequest -Uri $Url -UseBasicParsing -UserAgent $userAgent -TimeoutSec 45
$response.RawContentStream.Position = 0
$reader = New-Object System.IO.StreamReader($response.RawContentStream, [System.Text.Encoding]::UTF8, $true)
$html = $reader.ReadToEnd()
$reader.Dispose()
$terms = @(Get-KeyTermsFromHtml $html)

if ($terms.Count -eq 0) {
  throw "No key terms were found at $Url. Expected OpenStax <dl><dt>term</dt><dd>definition</dd></dl> blocks."
}

$clusters = @(
  foreach ($item in $terms) {
    [ordered]@{
      stims = @(
        [ordered]@{
          response = [ordered]@{
            correctResponse = $item.term
          }
          display = [ordered]@{
            text = $item.definition
          }
        }
      )
    }
  }
)

$stimDoc = [ordered]@{
  setspec = [ordered]@{
    clusters = $clusters
  }
}

$lastCluster = $terms.Count - 1
$sourceUrlHtml = [System.Net.WebUtility]::HtmlEncode($Url)
$lessonNameHtml = [System.Net.WebUtility]::HtmlEncode($LessonName)
$bookTitleHtml = [System.Net.WebUtility]::HtmlEncode($BookTitle)
$chapterLabelHtml = [System.Net.WebUtility]::HtmlEncode($ChapterLabel)

$instructions = @"
<h2>$lessonNameHtml</h2><p>This tutor practices $($terms.Count) key terms from $bookTitleHtml, $chapterLabelHtml. Each card gives you a textbook definition, and you type the matching anatomy and physiology term from memory.</p><ul><li><strong>What you will do:</strong> Read the definition and enter the exact key term it describes.</li><li><strong>Timing:</strong> Study and drill screens last about 10 seconds, review screens last about 5 seconds, and correct confirmations flash for about 0.5 seconds.</li><li><strong>How it works:</strong> Immediate feedback connects the definition to the correct term, while adaptive scheduling brings uncertain terms back sooner.</li><li><strong>Study tip:</strong> Pay attention to directional, cavity, imaging, and homeostasis vocabulary because many terms are closely related.</li></ul><p><strong>Source and attribution:</strong> Terms and definitions are from OpenStax <em>$bookTitleHtml</em>, $chapterLabelHtml Key Terms. Access for free at <a href="$sourceUrlHtml" target="_blank" rel="noopener noreferrer">$sourceUrlHtml</a>. OpenStax textbook content is licensed under the Creative Commons Attribution 4.0 International License.</p>
"@

$tdfDoc = [ordered]@{
  tutor = [ordered]@{
    setspec = [ordered]@{
      lessonname = $LessonName
      stimulusfile = $StimFileName
      shuffleclusters = "0-$lastCluster"
      userselect = 'true'
      lfparameter = '0.85'
      enableAudioPromptAndFeedback = 'true'
      speechAPIKey = 'YOUR_GOOGLE_SPEECH_API_KEY'
      audioInputEnabled = 'true'
      audioPromptMode = 'feedback'
      textToSpeechAPIKey = 'YOUR_GOOGLE_TTS_API_KEY'
      speechIgnoreOutOfGrammarResponses = 'true'
    }
    unit = @(
      [ordered]@{
        unitname = 'Instructions'
        unitinstructions = $instructions
      },
      [ordered]@{
        unitname = 'Practice'
        learningsession = [ordered]@{
          clusterlist = "0-$lastCluster"
          unitMode = 'distance'
          calculateProbability = 'p.y = -0.77 + .665 * pFunc.logitdec( p.overallOutcomeHistory.slice( Math.max(p.overallOutcomeHistory.length-60,  0),   p.overallOutcomeHistory.length),  .966)+ .51* (p.stimSuccessCount) + 11.1 * pFunc.recency(p.stimSecsSinceLastShown,  .443) ; p.probability = 1.0 / (1.0 + Math.exp(-p.y));  return p'
        }
        deliveryparams = [ordered]@{
          lfparameter = '0.85'
          purestudy = '10000'
          drill = '10000'
          skipstudy = 'false'
          reviewstudy = '5000'
          correctprompt = '500'
          fontsize = '24'
          correctscore = '1'
          incorrectscore = '0'
          optimalThreshold = '.8'
          practiceseconds = '1000000'
          finalInstructions = "You are done practicing $LessonName. Thank you for using this tutor."
        }
        uiSettings = [ordered]@{
          displayReviewTimeoutAsBarOrText = 'false'
          displayReadyPromptTimeoutAsBarOrText = 'false'
          displayCardTimeoutAsBarOrText = $false
          displayTimeOutDuringStudy = $false
          displayPerformanceDuringStudy = $true
          singleLineFeedback = $true
          feedbackDisplayPosition = 'middle'
        }
      }
    )
  }
}

$stimPath = Join-Path $OutputDir $StimFileName
$tdfPath = Join-Path $OutputDir $TdfFileName
$sourceCsvPath = Join-Path $OutputDir ('{0}_source_terms.csv' -f (ConvertTo-SafeFileBase $LessonName))

Write-Utf8NoBom -Path $stimPath -Content ($stimDoc | ConvertTo-Json -Depth 8)
Write-Utf8NoBom -Path $tdfPath -Content ($tdfDoc | ConvertTo-Json -Depth 8)
$terms | Export-Csv -Path $sourceCsvPath -NoTypeInformation -Encoding UTF8

Write-Output ('Created stimulus file: {0}' -f $stimPath)
Write-Output ('Created TDF file: {0}' -f $tdfPath)
Write-Output ('Created source terms CSV: {0}' -f $sourceCsvPath)
Write-Output ('Extracted terms: {0}' -f $terms.Count)
