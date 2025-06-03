## Reviewed 03/06/2025
## Template Revision 1.1
param (
    [Parameter(Mandatory = $true)]
    [string]$ConfigXml
)

#---------- Script Variables ----------#
$ScriptVersion = "v1.0"
$InstallerUrl = "https://officecdn.microsoft.com/pr/wsus/setup.exe"
$InstallerPath = "$PSScriptRoot\setup.exe"
$ConfigXmlPath = Join-Path -Path $PSScriptRoot -ChildPath $ConfigXml

#---------- Common Script Variables ----------#
$GHSKey = "HKLM:\SOFTWARE\GHS"
$GHSDir = "$($ENV:ALLUSERSPROFILE)\GHS"
$LogsDir = "$($GHSDir)\Logs"
$LogFile = "$($LogsDir)\App_MicrosoftOfficeDesktopApps.log"
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
Add-LogMessage -message "Starting script: Uninstall Microsoft Office Desktop Apps"

#---------- Script Content Here! ----------#

# Check if XML file exists
if (-Not (Test-Path $ConfigXmlPath)) {
    Add-LogMessage -Message "Configuration XML file not found: $ConfigXmlPath" -fout
    exit 1
}

# Download the installer if not already present
if (-Not (Test-Path $InstallerPath)) {
    Add-LogMessage -Message "Downloading Office installer..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Add-LogMessage -Message "Download complete: $InstallerPath"
    } catch {
        Add-LogMessage -Message "Failed to download installer: $_" -fout
        exit 1
    }
} else {
    Add-LogMessage -Message "Installer already exists at: $InstallerPath"
}

# Run the installer with the config XML
Add-LogMessage -Message "Running Office installer with uninstall config: $ConfigXmlPath"
try {
    Start-Process -FilePath $InstallerPath -ArgumentList "/configure `"$ConfigXmlPath`"" -Wait -NoNewWindow
    Add-LogMessage -Message "Office installation initiated."
} catch {
    Add-LogMessage -Message "Failed to start installer: $_" -fout
    exit 1
}

#---------- Script End ----------#

# Logging completion of script
Add-LogMessage -message "Ending script"