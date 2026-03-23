param(
  [Parameter(Mandatory = $true)]
  [string]$TargetRoot,

  [string]$ProjectName = '待填',
  [string]$RepositoryName = '待填',
  [string]$RepositoryUrl = '待填',
  [string]$RepositoryVisibility = '待填',
  [string]$ProjectGoal = '待填',
  [string]$TargetUsers = '待填',
  [string]$CoreFeatures = '待填',
  [string]$TechStack = '待填',
  [string]$ReleaseStrategy = '待填',
  [string]$DataStrategy = '待填',
  [string]$OpenQuestions = '待填',
  [string]$UseMerForkProtocol = '待填',

  [switch]$InitializeGit
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateRoot = Split-Path -Parent $scriptDir

if (-not (Test-Path $TargetRoot)) {
  New-Item -ItemType Directory -Path $TargetRoot | Out-Null
}

$dirMap = @(
  'docs',
  'notes',
  'scripts'
)

foreach ($dir in $dirMap) {
  $targetDir = Join-Path $TargetRoot $dir
  if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
  }
  $gitkeep = Join-Path $targetDir '.gitkeep'
  if (-not (Test-Path $gitkeep)) {
    New-Item -ItemType File -Path $gitkeep | Out-Null
  }
}

$copyMap = @(
  @{ Source = 'README.md'; Target = 'README.md' },
  @{ Source = 'START_HERE.md'; Target = 'START_HERE.md' },
  @{ Source = 'HANDOFF.md'; Target = 'HANDOFF.md' },
  @{ Source = 'PROJECT_STRUCTURE.md'; Target = 'PROJECT_STRUCTURE.md' },
  @{ Source = 'PROJECT_BRIEF.md'; Target = 'PROJECT_BRIEF.md' },
  @{ Source = 'INITIAL_CHECKLIST.md'; Target = 'INITIAL_CHECKLIST.md' },
  @{ Source = 'RELEASE_NOTES.md'; Target = 'RELEASE_NOTES.md' },
  @{ Source = 'KNOWN_ISSUES.md'; Target = 'KNOWN_ISSUES.md' },
  @{ Source = 'NEW_REPO_SETUP.md'; Target = 'NEW_REPO_SETUP.md' },
  @{ Source = 'SETUP_WITH_AI.md'; Target = 'SETUP_WITH_AI.md' },
  @{ Source = 'AI_FOLDER_START.md'; Target = 'AI_FOLDER_START.md' },
  @{ Source = 'WHY_MERFORK.md'; Target = 'WHY_MERFORK.md' },
  @{ Source = 'ERROR_TRIAGE.md'; Target = 'ERROR_TRIAGE.md' },
  @{ Source = 'FAILURE_RECOVERY.md'; Target = 'FAILURE_RECOVERY.md' },
  @{ Source = 'SUPABASE_AI_ACCESS.md'; Target = 'SUPABASE_AI_ACCESS.md' },
  @{ Source = 'gitignore.template'; Target = '.gitignore' },
  @{ Source = 'scripts/bootstrap-new-repo.ps1'; Target = 'scripts/bootstrap-new-repo.ps1' }
)

foreach ($item in $copyMap) {
  Copy-Item -Path (Join-Path $templateRoot $item.Source) -Destination (Join-Path $TargetRoot $item.Target) -Force
}

function Normalize-Field {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return 'TBD'
  }
  return $Value.Trim()
}

function Format-ListBlock {
  param([string]$Value)
  $items = $Value -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  if (-not $items) {
    return @('- TBD')
  }
  return $items | ForEach-Object { "- $_" }
}

$projectNameText = Normalize-Field $ProjectName
$repositoryNameText = Normalize-Field $RepositoryName
$repositoryUrlText = Normalize-Field $RepositoryUrl
$repositoryVisibilityText = Normalize-Field $RepositoryVisibility
$projectGoalText = Normalize-Field $ProjectGoal
$targetUsersText = Normalize-Field $TargetUsers
$techStackText = Normalize-Field $TechStack
$releaseStrategyText = Normalize-Field $ReleaseStrategy
$dataStrategyText = Normalize-Field $DataStrategy
$openQuestionsText = Normalize-Field $OpenQuestions
$useProtocolText = Normalize-Field $UseMerForkProtocol
$featureLines = Format-ListBlock $CoreFeatures

$intakeLines = [System.Collections.Generic.List[string]]::new()
$intakeLines.Add('# Project Intake')
$intakeLines.Add('')
$intakeLines.Add('## Project Name')
$intakeLines.Add($projectNameText)
$intakeLines.Add('')
$intakeLines.Add('## Repository Name')
$intakeLines.Add($repositoryNameText)
$intakeLines.Add('')
$intakeLines.Add('## Repository URL')
$intakeLines.Add($repositoryUrlText)
$intakeLines.Add('')
$intakeLines.Add('## Repository Visibility')
$intakeLines.Add($repositoryVisibilityText)
$intakeLines.Add('')
$intakeLines.Add('## Project Goal')
$intakeLines.Add($projectGoalText)
$intakeLines.Add('')
$intakeLines.Add('## Target Users')
$intakeLines.Add($targetUsersText)
$intakeLines.Add('')
$intakeLines.Add('## Core Features')
foreach ($line in $featureLines) {
  $intakeLines.Add($line)
}
$intakeLines.Add('')
$intakeLines.Add('## Tech Stack')
$intakeLines.Add($techStackText)
$intakeLines.Add('')
$intakeLines.Add('## Release Strategy')
$intakeLines.Add($releaseStrategyText)
$intakeLines.Add('')
$intakeLines.Add('## Data / Report Strategy')
$intakeLines.Add($dataStrategyText)
$intakeLines.Add('')
$intakeLines.Add('## Open Questions / Needs AI Help')
$intakeLines.Add($openQuestionsText)
$intakeLines.Add('')
$intakeLines.Add('## Use MerFork Protocol')
$intakeLines.Add($useProtocolText)

Set-Content -Path (Join-Path $TargetRoot 'PROJECT_INTAKE.md') -Value $intakeLines.ToArray() -Encoding utf8

$briefLines = [System.Collections.Generic.List[string]]::new()
$briefLines.Add('# Project Brief')
$briefLines.Add('')
$briefLines.Add('## Project Name')
$briefLines.Add($projectNameText)
$briefLines.Add('')
$briefLines.Add('## Repository Name')
$briefLines.Add($repositoryNameText)
$briefLines.Add('')
$briefLines.Add('## Repository URL')
$briefLines.Add($repositoryUrlText)
$briefLines.Add('')
$briefLines.Add('## Repository Visibility')
$briefLines.Add($repositoryVisibilityText)
$briefLines.Add('')
$briefLines.Add('## Project Goal')
$briefLines.Add($projectGoalText)
$briefLines.Add('')
$briefLines.Add('## Non Goals')
$briefLines.Add('TBD')
$briefLines.Add('')
$briefLines.Add('## Target Users')
$briefLines.Add($targetUsersText)
$briefLines.Add('')
$briefLines.Add('## Core Features')
foreach ($line in $featureLines) {
  $briefLines.Add($line)
}
$briefLines.Add('')
$briefLines.Add('## Tech Decisions to Keep')
$briefLines.Add($techStackText)
$briefLines.Add('')
$briefLines.Add('## Release Strategy')
$briefLines.Add($releaseStrategyText)
$briefLines.Add('')
$briefLines.Add('## Data / Report Strategy')
$briefLines.Add($dataStrategyText)
$briefLines.Add('')
$briefLines.Add('## Open Questions / Needs AI Help')
$briefLines.Add($openQuestionsText)

Set-Content -Path (Join-Path $TargetRoot 'PROJECT_BRIEF.md') -Value $briefLines.ToArray() -Encoding utf8

if ($InitializeGit) {
  Push-Location $TargetRoot
  try {
    git init
    git add .
    git commit -m "Initial MerFork ready scaffold"
  } finally {
    Pop-Location
  }
}

Write-Host "MerFork ready scaffold copied to $TargetRoot"
Write-Host "Next: review PROJECT_INTAKE.md and start the new repo from there."
