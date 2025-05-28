## Reviewed 13/05/2025
## Template Revision 1.1

#---------- Script Variables ----------#
$ScriptName = "App_QualysAgent_Uninstall"
$ScriptVersion = "v2.0"

#---------- Common Script Variables ----------#
$GHSKey = "HKLM:\SOFTWARE\GHS"
$GHSDir = "$($ENV:ALLUSERSPROFILE)\GHS"
$LogsDir = "$($GHSDir)\Logs"
$LogFile = "$($LogsDir)\$($scriptName).log"
$ShowConsoleOutput = $true #log to console & log file

#---------- Functions ----------#
# Function to detect Qualys Agent
function Test-QualysExistence {
    $RegPath = "HKLM:\SOFTWARE\Qualys"
    $FilePath = "C:\Program Files\Qualys\QualysAgent\QualysAgent.exe"
    $ServiceName = "Qualys Cloud Agent"
    $signsOfLife = $false

    # Check registry values
    try {
        $regActivationID = Get-ItemProperty -Path $RegPath -Name "ActivationID" -ErrorAction Stop | Select-Object -ExpandProperty ActivationID
        $regCustomerID = Get-ItemProperty -Path $RegPath -Name "CustomerID" -ErrorAction Stop | Select-Object -ExpandProperty CustomerID
        Add-LogMessage -message "Activation & Customer ID registry keys exist"
        $signsOfLife = $true
    } catch {
        Add-LogMessage -message "Activation & Customer ID registry keys don't exist"
    }

    # Check if file exists
    if (Test-Path -Path $FilePath) {
        Add-LogMessage -message "QualysAgent.exe found"
        $signsOfLife = $true
    } else {
        Add-LogMessage -message "QualysAgent.exe not found"
    }

    # Check if service is running
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -eq $service -or $service.Status -ne 'Running') {
        Add-LogMessage -message "Qualys Cloud Agent service not running or missing"
    } elseif ($service.Status -eq 'Running') {
        Add-LogMessage -message "Qualys Cloud Agent service running"
        $signsOfLife = $true
    } else {
        Add-LogMessage -Message "Qualys service found, status unknown"
        $signsOfLife = $true
    }

    if ($signsOfLife) {
        Add-LogMessage -message "Found Qualys Settings or Files" -warning
        return $true
    } else {
        Add-LogMessage -Message "Qualys Settings and Files were not found"
        return $false
    }
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

# Exit if Script Already Ran
if (!(Test-QualysExistence)) {
    Exit 0
}

#---------- Script Content Here! ----------#

$UninstallPath = "C:\Program Files\Qualys\QualysAgent\uninstall.exe"
if (Test-Path $UninstallPath) {
    Add-LogMessage -message "Running uninstaller for existing version..."
    try {
        Start-Process -FilePath $UninstallPath -ArgumentList "Uninstall=True Force=True" -Verb RunAs -Wait
        Start-Sleep -Seconds 10
    } catch {
        Add-LogMessage -message "Uninstall failed: $_" -fout
        return $false
    }
} else {
    Add-LogMessage -message "Uninstall executable not found at $UninstallPath" -fout
    return $false
}

#---------- Script End ----------#

# Checking detection
Add-LogMessage -Message "Checking to ensure Qualys Agent uninstalled"
if (Test-QualysExistence) {
    Add-LogMessage -Message "Detected Qualys Agent, presumably uninstall failed" -fout
    Exit 1
} else {
    Add-LogMessage -Message "Successfully uninstalled"
    Exit 0
}