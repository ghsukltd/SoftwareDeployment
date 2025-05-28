## Reviewed 13/02/2025
## Version 2.0
## Template Revision 1.0

#---------- Script Variables ----------#
$ScriptName = "BitDefenderInstall"

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

# Exit if Script Already Ran
if (Test-Path "C:\Program Files\Bitdefender\Endpoint Security\EPConsole.exe") {
	Exit
}

# Logging start of script
Add-LogMessage -message "----------------------------------------------------------"
Add-LogMessage -message "Starting script: $($ScriptName)"

#---------- Script Content Here! ----------#

Add-LogMessage -Message "Starting Installer..."
# Export installer from BitDefender GravityZone portal. Rename to bitdefender_setup.exe and put the encoded text in the STRINGHERE variable below.
Start-Process -FilePath "$($PSScriptRoot)\bitdefender_setup.exe" -Wait -ArgumentList "/bdparams /silent /sourceUrlEnc=`"STRINGHERE`" /runParams=`"/silent rebootIfNeeded=1 forceResume=1`""
Add-LogMessage -Message "Installer started, waiting 60 seconds to ensure installed"
Start-Sleep -Seconds 60

while (!(Test-Path "C:\Program Files\Bitdefender\Endpoint Security\EPConsole.exe")) {
    Add-LogMessage -Message "EPConsole not found. Waiting further 60 seconds." -warning
    Start-Sleep -Seconds 60
}

#---------- Script End ----------#

# Logging completion of script
Add-LogMessage -message "Ending script"