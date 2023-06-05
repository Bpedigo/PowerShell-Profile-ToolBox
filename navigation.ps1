# This hashtable is for keys and paths
$goto = @{
    # Examples:
    # 'gdrive' for Google Drive backup directory
    # 'downloads' for Downloads folder
    # 'robloxOnly' for specific Roblox games directory
    # 'module' for PowerShell modules directory
    # Add more key-value pairs as needed
    gdrive     = "C:\Users\bpedi\OneDrive\Desktop\GoogleDriveBackUp\"
    downloads  = "C:\Users\bpedi\Downloads"
    robloxOnly = "C:\Users\bpedi\OneDrive\Desktop\GoogleDriveBackUp\robloxGamesOnly"
    module     = "C:\Users\bpedi\Documents\PowerShell\Modules"
    test       = "C:\"
    ace        = "C:\TesttingThingsMoved"
    txt        = "C:\TesttingThingsMoved\day4.txt"
    trash      = "C:\Users\bpedi\OneDrive\Desktop\Trash"
    python_LS  = 'C:\Users\bpedi\AppData\Local\Microsoft\WindowsApps'
    pyScripts  = "C:\Users\bpedi\OneDrive\Desktop\GoogleDriveBackUp\pythonOnly\FristLearning"
    JS_Ref     = "C:\Users\bpedi\OneDrive\Desktop\GoogleDriveBackUp\javaScriptOnly\refences"
}
# Go To Directory (goto)
function goto {
    $directory = $goto[$args[0]]
    if ($directory) {
        Set-Location $directory
    }
    else {
        Write-Host "Directory not found."
    }
}
# Change directory and open file explorer simultaneously (cd-ii)
function cd-ii {
    param ($par1)
  
    $directory = $goto[$par1]
    if ($directory) {
        Set-Location $directory
        Invoke-Item $directory
    }
    elseif (Test-Path $par1) {
        Set-Location $par1
        Invoke-Item $par1
    }
    else {
        Write-Host "Directory not found."
    }
}
# Add a path to the goto hashtable works for current shell only
function Add-GotoPath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$true)]
        [string]$Value
    )
  
    $goto[$Key] = $Value
    Write-Host "Path '$Value' added with key '$Key' to the goto table."
}
# Show available paths in the goto hashtable
function show-goto() {
    Write-Host '[',$goto.Count,'] ' -ForegroundColor Red -NoNewline
    foreach ($key in $goto.Keys) {
      Write-Host $key,' '  -ForegroundColor Green -NoNewline
    } 
}