## Reviewed 19/05/2025
## Template Revision 1.1

#---------- Script Variables ----------#
$ScriptName = "App_Uninstall_.NetBelow8"
$ScriptVersion = "v1.1"

#---------- Common Script Variables ----------#
$GHSKey = "HKLM:\SOFTWARE\GHS"
$GHSDir = "$($ENV:ALLUSERSPROFILE)\GHS"
$LogsDir = "$($GHSDir)\Logs"
$LogFile = "$($LogsDir)\$($scriptName).log"
$ShowConsoleOutput = $true #log to console & log file

#---------- Functions ----------#
# Function to Log Messages
function Add-LogMessage {
    param (
        [Parameter(Mandatory=$true)][string]$Message,
        [Switch]$fout,
        [Switch]$warning
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if($fout){
        $Message = "$($timestamp) | ERROR | $($Message)"
    }
    elseif($warning){
        $Message = "$($timestamp) | WARNING | $($Message)"
    }
    else{
        $Message = "$($timestamp) | INFO | $($Message)"
    }
    try{
        Add-Content $LogFile $Message
    }catch{$Null}
    if ($ShowConsoleOutput) {
        if ($fout) {
            Write-Host $Message -ForegroundColor Red
        } elseif ($warning) {
            Write-Host $Message -ForegroundColor Yellow
        } else {
            Write-Host $Message -ForegroundColor Green
        }
    }
}

#---------- Script Start / Initialisation ----------#
# Check if common areas exist, if not create
if (-not (Test-Path $GHSKey)) { New-Item -Path $GHSKey | Out-Null }
if (-not (Test-Path $GHSDir)) { New-Item -Path $GHSDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $LogsDir)) { New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null }

# Check Log File Size
if (Test-Path $LogFile) {
    if ((Get-Item $LogFile).Length -gt 2MB) {
        Rename-Item $LogFile "$LogFile.bak" -Force
    }
}

# Logging start of script
Add-LogMessage -message "----------------------------------------------------------"
Add-LogMessage -message "Starting script: $($ScriptName) - $($ScriptVersion)"

#---------- Script Content Here! ----------#

# Run as Admin
Write-Host "Starting .NET Core and Windows Desktop Runtime cleanup..." -ForegroundColor Cyan

# Target registries for both 64-bit and 32-bit programs
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Get all matching runtime entries
$allRuntimes = foreach ($path in $registryPaths) {
    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
        ($_.DisplayName -match "Microsoft \.NET Runtime.+" -or
         $_.DisplayName -match "Microsoft Windows Desktop Runtime.+") -and
         ($_.DisplayName -notmatch "^.+8(\.|$)")
    }
}

if ($allRuntimes.Count -eq 0) {
    Add-LogMessage -Message "No older .NET Core or Windows Desktop runtimes found."
    return
}

foreach ($runtime in $allRuntimes) {
    Add-LogMessage -Message "Removing: $($runtime.DisplayName) ($($runtime.DisplayVersion))"
    try {
        if ($runtime.UninstallString) {
            $uninstallCmd = $runtime.UninstallString

            # Some uninstall strings are quoted or have extra arguments
            if ($uninstallCmd -match 'msiexec') {
                Start-Process "msiexec.exe" -ArgumentList "/x $($runtime.PSChildName) /quiet /norestart" -Wait
            } else {
                Start-Process "cmd.exe" -ArgumentList "/c $uninstallCmd /quiet /norestart" -Wait
            }

            Add-LogMessage -Message "Removed $($runtime.DisplayName)"
        } else {
            Add-LogMessage -Message "Uninstall string not found for: $($runtime.DisplayName)" -fout
        }
    } catch {
        Add-LogMessage -Message "Failed to uninstall $($runtime.DisplayName): $_" -fout
    }
}

Add-LogMessage -Message "Cleanup complete"

## Check
$allRuntimes = foreach ($path in $registryPaths) {
    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
        ($_.DisplayName -match "Microsoft \.NET Runtime.+" -or
         $_.DisplayName -match "Microsoft Windows Desktop Runtime.+") -and
         ($_.DisplayName -notmatch "^.+8(\.|$)")
    }
}

if ($allRuntimes.Count -eq 0) {
    Write-Output "No old versions found - success!"
    Exit 0
} else {
    Write-Output "ERROR! - Found old versions"
    Exit 1
}