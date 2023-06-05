
function settings {
    param (
      [Parameter(Mandatory=$true, Position=0)]
      [ValidateSet("update", "uninstall", "about", "task", "disk", "cleaner", "winver", "mobility", "power", "event", "system", "path", "properties", "device")]
      [string]$Action
    )
  
    <#
      .SYNOPSIS
      Launches various Windows settings and tools using the ms-settings protocol.
    
      .DESCRIPTION
      The settings function allows you to quickly launch different Windows settings and tools using the ms-settings protocol. You can perform actions such as updating Windows, uninstalling apps, accessing system information, opening Task Manager, managing disks, running Disk Cleanup, viewing Windows version information, and more.
    
      .PARAMETER Action
      Specifies the action to perform. Available options are:
        - 'update': Launches Windows Update settings.
        - 'uninstall': Launches Apps & Features settings for uninstalling apps.
        - 'about': Launches About settings for system information.
        - 'task': Opens Task Manager.
        - 'disk': Opens Disk Management.
        - 'cleaner': Runs Disk Cleanup.
        - 'winver': Displays Windows version information.
        - 'mobility': Launches Windows Mobility Center.
        - 'power': Launches Power Options settings.
        - 'event': Launches Event Viewer.
        - 'system': Launches System settings.
        - 'path': Launches Environment Variables settings.
        - 'properties': Launches System Properties settings.
        - 'device': Launches Device Manager.
    
      .EXAMPLE
      settings -Action update
      Launches the Windows Update settings.
    
      .EXAMPLE
      settings -Action uninstall
      Launches the Apps & Features settings.
    
      .EXAMPLE
      settings -Action task
      Opens Task Manager.
    
      .EXAMPLE
      settings -Action winver
      Displays the Windows version information.
    
      .NOTES
      Author: Brian Pedigo
      Date: June 2023
    #>
  
    switch ($Action) {
      "update" { Start-Process 'ms-settings:windowsupdate' }
      "uninstall" { Start-Process 'ms-settings:appsfeatures' }
      "about" { Start-Process 'ms-settings:about' }
      "task" { Taskmgr.exe }
      "disk" { diskmgmt.msc }
      "cleaner" { cleanmgr.exe }
      "winver" { winver.exe }
      "mobility" { Start-Process 'ms-settings:easeofaccess-windowsmobilitycenter' }
      "power" { Start-Process 'ms-settings:powersleep' }
      "event" { Start-Process 'eventvwr.msc' }
      "system" { Start-Process 'ms-settings:windowsdefender' }
      "path" { Start-Process 'rundll32.exe' -ArgumentList 'sysdm.cpl,EditEnvironmentVariables' }
      "properties" { Start-Process 'rundll32.exe' -ArgumentList 'sysdm.cpl,SystemPropertiesAdvanced' }
      "device" { Start-Process 'devmgmt.msc' }
    }
    
}

function Get-Software() {
    <#
          .SYNOPSIS
          Reads installed software from registry
  
          .PARAMETER DisplayName
          Name or part of name of the software you are looking for
  
          .EXAMPLE
          Get-Software -DisplayName *Office*
          returns all software with "Office" anywhere in its name
      #>
  
    param
    (
      # emit only software that matches the value you submit:
      [string]
      $DisplayName = '*'
    )
  
  
    #region define friendly texts:
    $Scopes = @{
      HKLM = 'All Users'
      HKCU = 'Current User'
    }
  
    $Architectures = @{
      $true  = '32-Bit'
      $false = '64-Bit'
    }
    #endregion
  
    #region define calculated custom properties:
    # add the scope of the software based on whether the key is located
    # in HKLM: or HKCU:
    $Scope = @{
      Name       = 'Scope'
      Expression = {
        $Scopes[$_.PSDrive.Name]
      }
    }
  
    # add architecture (32- or 64-bit) based on whether the registry key 
    # contains the parent key WOW6432Node:
    $Architecture = @{
      Name       = 'Architecture'
      Expression = { $Architectures[$_.PSParentPath -like '*\WOW6432Node\*'] }
    }
    #endregion
  
    #region define the properties (registry values) we are after
    # define the registry values that you want to include into the result:
    $Values = 'AuthorizedCDFPrefix',
    'Comments',
    'Contact',
    'DisplayName',
    'DisplayVersion',
    'EstimatedSize',
    'HelpLink',
    'HelpTelephone',
    'InstallDate',
    'InstallLocation',
    'InstallSource',
    'Language',
    'ModifyPath',
    'NoModify',
    'PSChildName',
    'PSDrive',
    'PSParentPath',
    'PSPath',
    'PSProvider',
    'Publisher',
    'Readme',
    'Size',
    'SystemComponent',
    'UninstallString',
    'URLInfoAbout',
    'URLUpdateInfo',
    'Version',
    'VersionMajor',
    'VersionMinor',
    'WindowsInstaller',
    'Scope',
    'Architecture'
    #endregion
  
    #region Define the VISIBLE properties
    # define the properties that should be visible by default
    # keep this below 5 to produce table output:
    [string[]]$visible = 'DisplayName', 'DisplayVersion', 'Scope', 'Architecture'
    [Management.Automation.PSMemberInfo[]]$visibleProperties = [System.Management.Automation.PSPropertySet]::new('DefaultDisplayPropertySet', $visible)
    #endregion
  
    #region read software from all four keys in Windows Registry:
    # read all four locations where software can be registered, and ignore non-existing keys:
    Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction Ignore |
    # exclude items with no DisplayName:
    Where-Object DisplayName |
    # include only items that match the user filter:
    Where-Object { $_.DisplayName -like $DisplayName } |
    # add the two calculated properties defined earlier:
    Select-Object -Property *, $Scope, $Architecture |
    # create final objects with all properties we want:
    Select-Object -Property $values |
    # sort by name, then scope, then architecture:
    Sort-Object -Property DisplayName, Scope, Architecture |
    # add the property PSStandardMembers so PowerShell knows which properties to
    # display by default:
    Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $visibleProperties -PassThru
    #endregion 
}

function Get-OSInfo {
    <#
      .SYNOPSIS
      Reads operating system information similar to winver.exe
  
      .EXAMPLE
      Get-OSInfo
      Returns properties found in winver.exe dialogs.
  
      .EXAMPLE
      Get-OSInfo | Select-Object -Property *
      Returns all information about your Windows operating system.
    #>
  
    [CmdletBinding()]
    param()
  
    # Define the visible properties that should be displayed by default
    [string[]]$visible = 'ProductName', 'ReleaseId', 'CurrentBuild', 'UBR', 'RegisteredOwner', 'RegisteredOrganization'
    [Management.Automation.PSMemberInfo[]]$visibleProperties = [System.Management.Automation.PSPropertySet]::new('DefaultDisplayPropertySet', $visible)
  
    # Read the operating system information from the registry
    Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
      Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $visibleProperties -PassThru
}

function Get-SystemInfo {
  <#
  .SYNOPSIS
  Retrieves system information including operating system, processor, memory, and disk capacity.
  
  .DESCRIPTION
  The Get-SystemInfo function retrieves various system information using WMI (Windows Management Instrumentation). It gathers details about the operating system, processor, memory, and disk capacity.
  
  .OUTPUTS
  The function outputs a custom object with the following properties:
  - OperatingSystem: The caption of the operating system.
  - Processor: The name of the processor.
  - Memory (GB): The total memory capacity in gigabytes (GB).
  - Disk Capacity (GB): The total disk capacity in gigabytes (GB).
  
  .EXAMPLE
  Get-SystemInfo
  Retrieves and displays system information including operating system, processor, memory, and disk capacity.
  #>
  
  [CmdletBinding()]
  param()
  
  $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
  $Processor = Get-WmiObject -Class Win32_Processor
  $Memory = Get-WmiObject -Class Win32_PhysicalMemory
  $Disks = Get-WmiObject -Class Win32_LogicalDisk
  
  $DiskCapacity = ($Disks | Measure-Object -Property Size -Sum).Sum
  $DiskCapacityGB = "{0:N2}" -f ($DiskCapacity / 1GB)
  
  [PSCustomObject]@{
      "OperatingSystem" = $OperatingSystem.Caption
      "Processor" = $Processor.Name
      "Memory (GB)" = "{0:N2}" -f ($Memory.Capacity / 1GB)
      "Disk Capacity (GB)" = $DiskCapacityGB
  } | Format-Table
}

function Clean-TempFiles {
  [CmdletBinding()]
  param()
  
  <#
  .SYNOPSIS
  Deletes temporary files from specified folders.
  
  .DESCRIPTION
  The Clean-TempFiles function deletes temporary files from the specified folders. It helps free up disk space by removing unnecessary temporary files. The function supports common parameters like -Verbose and -Debug.
  
  .EXAMPLE
  Clean-TempFiles
  Deletes temporary files from the default set of temporary folders.
  
  .NOTES
  Author: Brian Pedigo
  Date: June 2023
  #>
  
  $tempFolders = @(
      'C:\Windows\Temp\*'
      'C:\Windows\Prefetch\*'
      'C:\Documents and Settings\*\LocalSettings\temp\*'
      'C:\Users\*\Appdata\Local\temp\*'
  )

  foreach ($folder in $tempFolders) {
      try {
          $files = Get-ChildItem -Path $folder -Force -Recurse -File -ErrorAction Stop

          if ($files.Count -gt 0) {
              $files | Remove-Item -Force
              Write-Host "Deleted $($files.Count) files from $folder" -ForegroundColor Green
          } else {
              Write-Host "No files found in $folder" -ForegroundColor Yellow
          }
      }
      catch [System.UnauthorizedAccessException] {
          Write-Host "Access denied: $folder" -ForegroundColor Red
      }
      catch {
          Write-Host "Error deleting files from $folder $_" -ForegroundColor Red
      }
  }
}

  