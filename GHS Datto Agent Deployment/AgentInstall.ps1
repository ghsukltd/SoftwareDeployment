## Reviewed 26/02/2025
## Template Revision 1.1

#---------- Script Variables ----------#
$ScriptName = "Install_DattoAgent"
$ScriptVersion = "v1.0"
$SiteID="<paste your Site ID here>"

#---------- Common Script Variables ----------#
$GHSKey = "HKLM:\SOFTWARE\GHS"
$GHSDir = "$($ENV:ALLUSERSPROFILE)\GHS"
$LogsDir = "$($GHSDir)\Logs"
$LogFile = "$($LogsDir)\$($scriptName).log"
$ShowConsoleOutput = $true #log to console & log file

#---------- Functions ----------#
# Function to Check Script Status
function Get-ScriptStatus {
    param ($ScriptName)
    try {
        return $null -ne (Get-ItemProperty -Path $GHSKey -Name $scriptName -ErrorAction Stop).$scriptName
    } catch {
        return $false
    }
}

# Function to Mark Script as Ran
function Set-ScriptStatus {
    param (
        [Parameter(Mandatory=$true)][string]$ScriptName
    )
    New-ItemProperty -Path $GHSKey -Name $ScriptName -Value "1" -PropertyType "String" | Out-Null
}

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

# Function to check for elevated permissions
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check for elevated permissions
if (-not (Test-IsAdmin)) {
    Add-LogMessage -message "This script requires elevated permissions to run. Please run as an Administrator." -fout
    exit 1
}

# First check if Agent is installed and instantly exit if so
if (Get-Service CagService -ErrorAction SilentlyContinue) {
    Add-LogMessage -message  "Datto RMM Agent already installed on this device"
    exit
}

# Download the Agent
$AgentURL = "https://pinotage.centrastage.net/csm/profile/downloadAgent/$SiteID"
$DownloadStart = Get-Date
Add-LogMessage -message  "Starting Agent download at $(Get-Date -Format HH:mm) from $AgentURL"

# Ensure TLS 1.2 is used
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    Add-LogMessage -message  "Cannot download Agent due to invalid security protocol. The following security protocols are installed and available: $([enum]::GetNames([Net.SecurityProtocolType]))" -fout
    Add-LogMessage -message  "Agent download requires at least TLS 1.2 to succeed. Please install TLS 1.2 and rerun the script." -fout
    exit 1
}

# Download the agent installer
try {
    Invoke-WebRequest -Uri $AgentURL -OutFile "$env:TEMP\DRMMSetup.exe"
} catch {
    Add-LogMessage -message  "Agent installer download failed. Exit message:`r`n$($_.Exception.Message)" -fout
    exit 1
}
Add-LogMessage -message  "Agent download completed in $((Get-Date).Subtract($DownloadStart).Seconds) seconds`r`n"

# Install the Agent
$InstallStart = Get-Date
Add-LogMessage -message  "Starting Agent install to target site at $(Get-Date -Format HH:mm)..."
try {
    & "$env:TEMP\DRMMSetup.exe" | Out-Null
    Add-LogMessage -message  "Sleeping for 120 seconds"
    Start-Sleep -Seconds 120
    Add-LogMessage -message  "Agent install completed at $(Get-Date -Format HH:mm) in $((Get-Date).Subtract($InstallStart).Seconds) seconds."
} catch {
    Add-LogMessage -message  "Agent installation failed. Exit message:`r`n$($_.Exception.Message)"
    exit 1
} finally {
    # Remove the installer file
    Remove-Item "$env:TEMP\DRMMSetup.exe" -Force -ErrorAction SilentlyContinue
}

#---------- Script End ----------#

# Script Success Check
if (Get-Service CagService -ErrorAction SilentlyContinue) {
    # Mark Script as Ran
    Set-ScriptStatus $ScriptName
    Add-LogMessage -Message "Service detected. Marking script as successfully ran."
}

# Logging completion of script
Add-LogMessage -message "Ending script"