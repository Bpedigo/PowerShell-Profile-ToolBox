

function Duplicate {
    <#
    .SYNOPSIS
        Duplicates a file by creating multiple copies with incremented numbers in the file name.
    
    .DESCRIPTION
        The Duplicate-File function creates multiple copies of a specified file with incremented numbers in the file name.
    
    .PARAMETER Path
        Specifies the path of the file to be duplicated. This parameter is mandatory.
        
    .PARAMETER Times
        Specifies the number of times the file should be duplicated. The default value is 1.
    
    .EXAMPLE
        Duplicate-File -Path "C:\Folder\file.txt" -Times 3
        Duplicates the file "C:\Folder\file.txt" three times, resulting in "file1.txt", "file2.txt", and "file3.txt".
    
    .EXAMPLE
        Duplicate-File -Path "C:\Folder\file.txt"
        Duplicates the file "C:\Folder\file.txt" once, resulting in "file1.txt".
    
    .NOTES
        Author: Brian Pedigo
        Date: June 2023
    #>
  
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
        [string]$Path,
        
        [Parameter(Position = 1)]
        [int]$Times = 1
    )
  
    $directory = Split-Path -Path $Path -Parent
    $leaf = Split-Path -Path $Path -Leaf -Resolve
    $renamed = $leaf -split '\.'
    $fileName = $renamed[0]
    $fileExt = $renamed[1]
  
    $fileNames = foreach ($i in 1..$Times) {
        $newFileName = '{0}{1}.{2}' -f $fileName, $i, $fileExt
        Join-Path -Path $directory -ChildPath $newFileName
    }
  
    foreach ($name in $fileNames) {
        Copy-Item -Path $Path -Destination $name
    }
  
    $message = 'Duplicated {0} times.' -f $fileNames.Count
    Write-Output $message
}

function Trash {
    <#
    .SYNOPSIS
    Moves a file to the Recycle Bin.

    .DESCRIPTION
    The Trash function moves the specified file to the Recycle Bin. If the file doesn't exist, an error is displayed.

    .PARAMETER file
    Specifies the path to the file that will be moved to the Recycle Bin.

    .EXAMPLE
    Trash -file "C:\Path\to\File.txt"
    Moves the "File.txt" to the Recycle Bin.

    .EXAMPLE
    Trash "C:\Path\to\File.txt"
    Moves the "File.txt" to the Recycle Bin using positional parameter.

    .NOTES
        Author: Brian Pedigo
        Date: June 2023
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$file
    )
  
    Add-Type -AssemblyName Microsoft.VisualBasic
  
    $item = Get-Item -Path $file -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        Write-Error("'{0}' not found" -f $file)
    }
    else {
        $fullpath = $item.FullName
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fullpath, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
}

function Delete {
    <#
    .SYNOPSIS
    Deletes a file from the specified path.

    .DESCRIPTION
    The Delete function allows you to delete a file from the specified path. It checks if the file exists and then deletes it using the Remove-Item cmdlet.

    .PARAMETER FileName
    Specifies the name of the file to delete.

    .EXAMPLE
    Delete -FileName "file.txt"
    Deletes the file named "file.txt" from the current directory.

    .EXAMPLE
    Delete -FileName "C:\Documents\file.txt"
    Deletes the file named "file.txt" from the specified path "C:\Documents".

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string]$FileName
    )
  
    $FullPath = Join-Path -Path $PWD -ChildPath $FileName
  
    if (Test-Path -Path $FullPath) {
        Remove-Item -Path $FullPath -Force
        Write-Output "File '$FullPath' deleted successfully."
    }
    else {
        Write-Output "File '$FullPath' does not exist."
    }
}

function Rename {
    <#
    .SYNOPSIS
    Renames a file or folder.

    .DESCRIPTION
    The Rename function renames a file or folder at the specified path to the new name.

    .PARAMETER path
    Specifies the path to the file or folder to be renamed.

    .PARAMETER newName
    Specifies the new name for the file or folder.

    .EXAMPLE
    Rename -path "C:\Temp\file.txt" -newName "newfile.txt"
    Renames the file "file.txt" to "newfile.txt" in the "C:\Temp" directory.

    .EXAMPLE
    Rename -path "C:\Temp\folder" -newName "newfolder"
    Renames the folder "folder" to "newfolder" in the "C:\Temp" directory.
    #>

    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$path,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$newName
    )

    try {
        $item = Get-Item -Path $path -ErrorAction Stop
        $newPath = Join-Path -Path $item.DirectoryName -ChildPath $newName
        $item | Rename-Item -NewName $newPath -ErrorAction Stop
        Write-Host "File renamed successfully."
    }
    catch {
        Write-Error "Failed to rename the file: $_"
    }
}

function FileWatch {
    <#
    .SYNOPSIS
    Listens for changes to files in the current working directory (pwd).
    
    .DESCRIPTION
    The FileWatch function sets up a file system watcher to monitor changes to files in the current working directory.
    It can detect file creations, deletions, modifications, and renames, and executes the specified action when a change occurs.
    
    .PARAMETER Path
    The path to the directory to be monitored. If not specified, the current working directory (pwd) is used.
    
    .PARAMETER FileFilter
    The filter to apply to the files in the monitored directory. Default value is "*".
    
    .PARAMETER IncludeSubfolders
    Specifies whether to include subfolders in the monitoring process. Default value is $true.
    
    .PARAMETER Timeout
    The timeout value (in milliseconds) for the file watcher. Determines how often the watcher checks for changes. Default value is 1000.
    
    .EXAMPLE
    FileWatch -Path "C:\MyFolder" -FileFilter "*.txt" -IncludeSubfolders:$false -Timeout 2000
    Starts monitoring the directory "C:\MyFolder" for changes, including only the files with the ".txt" extension.
    Subfolders are excluded from monitoring, and the watcher checks for changes every 2 seconds.
    
    .NOTES
    - The FileWatch function uses the .NET FileSystemWatcher class to monitor file system changes.
    - Make sure you have appropriate permissions to access the specified directory and files.
    - Press Ctrl+C to stop the file watcher.
    
    #>

    [CmdletBinding()]
    param()
  
    $Path = Get-Location
    $FileFilter = '*'
    $IncludeSubfolders = $true
    $AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite
    $ChangeTypes = [System.IO.WatcherChangeTypes]::Created, [System.IO.WatcherChangeTypes]::Deleted, `
        [System.IO.WatcherChangeTypes]::Changed, [System.IO.WatcherChangeTypes]::Renamed
    $Timeout = 1000
  
    function NotifyFileChanged {
        param(
            [Parameter(Mandatory)]
            [System.IO.WaitForChangedResult]
            $ChangeInformation
        )
  
        $changeType = $ChangeInformation.ChangeType
        Write-Host "A file was $changeType"
    }
  
    $originalColor = $host.UI.RawUI.BackgroundColor
    $host.UI.RawUI.BackgroundColor = 'DarkCyan'
    Clear-Host
    
    try {
        Write-Host "File watcher is monitoring $Path"
    }
    catch {
        Write-Error "Failed to start file watcher: $_"
    }
  
    $watcher = New-Object -TypeName IO.FileSystemWatcher -ArgumentList $Path, $FileFilter -Property @{
        IncludeSubdirectories = $IncludeSubfolders
        NotifyFilter          = $AttributeFilter
    }
  
    do {
        try {
            $result = $watcher.WaitForChanged($ChangeTypes, $Timeout)
            if ($result.TimedOut) { continue }
  
            NotifyFileChanged -ChangeInformation $result
        }
        catch {
            Write-Error "Error occurred while watching files: $_"
        }
    } while ($true)
  
    $watcher.Dispose()
    $host.UI.RawUI.BackgroundColor = $originalColor
    Clear-Host
}

function Touch {
    <#
    .SYNOPSIS
    Updates the LastWriteTime of existing files or creates new files if they don't exist.

    .DESCRIPTION
    The Touch function updates the LastWriteTime of existing files or creates new files with the current timestamp if they don't exist. It can be used to refresh the timestamp of files or create placeholder files.

    .PARAMETER Path
    Specifies the path of the file(s) to touch. Accepts pipeline input.

    .EXAMPLE
    Touch file1.txt
    Updates the LastWriteTime of file1.txt to the current timestamp.

    .EXAMPLE
    "file1.txt", "file2.txt" | Touch
    Updates the LastWriteTime of file1.txt and file2.txt to the current timestamp.

    .NOTES
    The Touch function is similar to the Unix touch command, allowing you to quickly update the timestamp of files in a convenient way.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path
    )
  
    process {
        foreach ($file in $Path) {
            if (Test-Path $file) {
                Set-ItemProperty -Path $file -Name LastWriteTime -Value (Get-Date)
            }
            else {
                New-Item -Path $file -ItemType File -Force | Out-Null
            }
        }
    }
}
