## Reviewed 13/05/2025
## Template Revision 1.1

#---------- Script Variables ----------#
$ScriptName = "App_QualysAgent_Install"
$ScriptVersion = "v2.0"
## To be configured prior to deployment - provided by CS ##
$activationid = ""
$customerid = ""

#---------- Common Script Variables ----------#
$GHSKey = "HKLM:\SOFTWARE\GHS"
$GHSDir = "$($ENV:ALLUSERSPROFILE)\GHS"
$LogsDir = "$($GHSDir)\Logs"
$LogFile = "$($LogsDir)\$($scriptName).log"
$ShowConsoleOutput = $true #log to console & log file

#---------- Functions ----------#
# Function to detect Qualys Agent
function Test-QualysInstall {
    param (
        [string]$ActivationID,
        [string]$CustomerID,
        [switch]$UninstallIfMismatch
    )
    $RegPath = "HKLM:\SOFTWARE\Qualys"
    $FilePath = "C:\Program Files\Qualys\QualysAgent\QualysAgent.exe"
    $ServiceName = "Qualys Cloud Agent"
    $UninstallPath = "C:\Program Files\Qualys\QualysAgent\uninstall.exe"

    # Check registry values
    try {
        $regActivationID = Get-ItemProperty -Path $RegPath -Name "ActivationID" -ErrorAction Stop | Select-Object -ExpandProperty ActivationID
        $regCustomerID = Get-ItemProperty -Path $RegPath -Name "CustomerID" -ErrorAction Stop | Select-Object -ExpandProperty CustomerID
    } catch {
        Add-LogMessage -message "Activation & Customer ID registry keys don't exist"
        return $false
    }

    if ($regActivationID -ne $ActivationID -or $regCustomerID -ne $CustomerID) {
        Add-LogMessage -message "Registry values indicate a legacy or mismatched version already installed" -warning

        if ($UninstallIfMismatch) {
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
            return $false
        } else {
            return $false
        }
    }

    # Check if file exists
    if (-not (Test-Path -Path $FilePath)) {
        Add-LogMessage -message "QualysAgent.exe not found"
        return $false
    }

    # Check if service is running
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -eq $service -or $service.Status -ne 'Running') {
        Add-LogMessage -message "Qualys Cloud Agent service not running or missing"
        return $false
    }

    Add-LogMessage -message "OK! - Found Qualys Settings & Files - All verified"
    return $true
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
if (Test-QualysInstall -ActivationID $activationid -CustomerID $customerid -UninstallIfMismatch) {
    Add-LogMessage -message "Qualys is already installed - with the correct settings"
    Exit 0
}

#---------- Script Content Here! ----------#

$parms = "CustomerId={$customerid} ActivationID={$activationid} WebServiceUri=https://qagpublic.qg2.apps.qualys.eu/CloudAgent/"
$parms = $Parms.Split(" ")
$downloadurl = "https://cs-audit-qualys-public.s3.eu-west-2.amazonaws.com/qualysAgent/QualysCloudAgent.exe"
$templocation = "$env:TMP\\QualysCloudAgent.exe"

## Downloads the Qualys Agent
Add-LogMessage -message "Downloading Qualys"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($downloadurl, $templocation)

## Runs the Qualys Cloud Agent with Parameters
Add-LogMessage -message "Installing Qualys"
Start-Process -FilePath "$templocation" -Argumentlist "$parms" -Verb RunAs -Wait
Start-Sleep -Seconds 10
Remove-Item $templocation -Force

#---------- Script End ----------#

# Checking detection
Add-LogMessage -Message "Checking to ensure Qualys Agent installed and running with correct settings..."
if (Test-QualysInstall -ActivationID $activationid -CustomerID $customerid) {
    Add-LogMessage -Message "Ending script. Successfully installed."
    Exit 0
} else {
    Add-LogMessage -Message "Ending script. Something went wrong." -fout
    Exit 1
}