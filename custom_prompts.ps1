
$compactMode = $false

function ffcounter {
  $fileCount = (Get-ChildItem -File | Measure-Object).Count
  $folderCount = (Get-ChildItem -Directory | Measure-Object).Count
  $currentDirectory = (Get-Location).Path

  if ($currentDirectory.Length -gt 30 -and -not $compactMode) {
    $currentDirectory = "..." + $currentDirectory.Substring($currentDirectory.Length - 27)
  } else {
    $currentDirectory = (Get-Location | Split-Path -Leaf)
  }

  $promptText = ""
  if ($compactMode) {
    $promptText = "[{0}f/{1}d] " -f $fileCount, $folderCount
  } else {
    $fileText = "[{0}]files" -f $fileCount
    $folderText = "[{0}]folders" -f $folderCount
    $promptText = "{0}{1}> " -f $fileText, $folderText
  }

  $blueColor = [ConsoleColor]::Blue
  $whiteColor = [ConsoleColor]::White

  Write-Host $promptText -ForegroundColor $blueColor -NoNewline
  Write-Host $currentDirectory"> " -ForegroundColor $whiteColor -NoNewline
}

function LastCommandPrompt {
if ((Get-History) -and (Get-History)[-1]) {
    $lastCommand = (Get-History)[-1].CommandLine
} else {
    $lastCommand = "No history"
}

$currentDirectory = (Get-Location | Split-Path -Leaf)

$promptText = "[ {0} ]" -f $lastCommand
$folder = "...{0}> " -f $currentDirectory
$blueColor = [ConsoleColor]::Blue
$whiteColor = [ConsoleColor]::White

Write-Host $promptText -ForegroundColor $blueColor -NoNewline
Write-Host $folder -ForegroundColor $whiteColor -NoNewline
}

function Prompt() {
    #pick one and comment out the other
    # ffcounter 
    LastCommandPrompt
}