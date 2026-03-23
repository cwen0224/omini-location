param(
  [Parameter(Mandatory = $true)]
  [string]$TargetRoot,

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
  @{ Source = 'create_merfork_project.bat'; Target = 'create_merfork_project.bat' },
  @{ Source = 'gitignore.template'; Target = '.gitignore' },
  @{ Source = 'scripts/bootstrap-new-repo.ps1'; Target = 'scripts/bootstrap-new-repo.ps1' }
)

foreach ($item in $copyMap) {
  Copy-Item -Path (Join-Path $templateRoot $item.Source) -Destination (Join-Path $TargetRoot $item.Target) -Force
}

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
Write-Host "Next: fill PROJECT_BRIEF.md and start the new repo from there."
