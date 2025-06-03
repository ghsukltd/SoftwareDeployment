## Sophos Install and UUID Verification
## Reviewed 21/02/2025
## Template Revision 1.1

#---------- Script Variables ----------#
$ScriptName = "Install_SophosCentral"
$ScriptVersion = "v2.0"
$expectedTenantUUID = "aaaa"
$sophosInstaller = "\\serverpath\SophosSetup.exe"
#$sophosInstaller = "$($PSScriptRoot)\SophosSetup.exe"

#---------- Common Script Variables ----------#
$GHSKey = "HKLM:\SOFTWARE\GHS"
$GHSDir = "$($ENV:ALLUSERSPROFILE)\GHS"
$LogsDir = "$($GHSDir)\Logs"
$LogFile = "$($LogsDir)\$($scriptName).log"
$ShowConsoleOutput = $true #log to console & log file
$registryPath = "HKLM:\SOFTWARE\Sophos\Management\Policy\Authority"
$MCSendpoint = "Sophos\Management Communications System\Endpoint\McsClient.exe"

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

function Install-Sophos {
    Add-LogMessage -message "Installing Sophos..."
    Start-Process -FilePath $sophosInstaller -ArgumentList "--quiet" -Wait
}

function Update-SophosRegistration {
    Add-LogMessage -message "Checking Sophos registration..."
    # Get all child keys under the specified base path
    $childKeys = Get-ChildItem -Path $registryPath | Sort-Object PSChildName -Descending
    if ($childKeys.Count -eq 0) {
        Add-LogMessage -Message "No Sophos registration keys found." -warning
        return
    }
    $newestKey = $childKeys[0]
    # Construct the full path to the current key
    $fullPath = Join-Path -Path $registryPath -ChildPath $newestKey.PSChildName
    # Attempt to read the target value
    $tenantIdValue = (Get-ItemProperty -Path $fullPath -Name "tenantId" -ErrorAction SilentlyContinue).tenantId
    if ($null -ne $tenantIdValue) {
        # Check if the value matches the expected one
        if ($tenantIdValue -ne $expectedTenantUUID) {
            Add-LogMessage -Message "Already installed - Current UUID $($tenantIdValue)"
            Add-LogMessage -Message "Ensure Tamper Protection is turned off, otherwise this will fail" -warning
            Add-LogMessage -message "Moving to correct Estate..."
            Start-Process -FilePath $sophosInstaller -ArgumentList "--quiet","--registeronly" -Wait
        } else {
            Add-LogMessage -message "Already Installed, already on correct Estate"
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

# Determine the processor architecture
$programFilesPath = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { ${env:ProgramFiles(x86)} } else { $env:ProgramFiles }
$MCSPath = Join-Path -Path $programFilesPath -ChildPath $MCSendpoint
Add-LogMessage -Message "Script started with architecture: $env:PROCESSOR_ARCHITECTURE"

# Check and install/update Sophos
if (-not (Test-Path $MCSPath)) {
    Install-Sophos
} else {
    Update-SophosRegistration
    Start-Sleep -Seconds 60
}

#---------- Script End ----------#

# Script Success Check
if (Test-Path $MCSPath) {
    $childKeys = Get-ChildItem -Path $registryPath | Sort-Object PSChildName -Descending
    if ($childKeys.Count -eq 0) {
        Add-LogMessage -Message "No Sophos registration keys found." -warning
        return
    }
    $newestKey = $childKeys[0]
    # Construct the full path to the current key
    $fullPath = Join-Path -Path $registryPath -ChildPath $newestKey.PSChildName
    # Attempt to read the target value
    $tenantIdValue = (Get-ItemProperty -Path $fullPath -Name "tenantId" -ErrorAction SilentlyContinue).tenantId
    if ($tenantIdValue -eq $expectedTenantUUID) {
        # Mark Script as Ran
        Add-LogMessage -Message "Correct UUID found :)"
    } else {
        Add-LogMessage -Message "Failed to detect correct UUID - Current UUID $($tenantIdValue)" -fout
        Add-LogMessage -Message "Ensure Tamper Protection is turned off, otherwise this will fail" -fout
    }
} else {
    Add-LogMessage -Message "Failed to detect Sophos MCS - installer may still be running, or failed." -fout
}

# Logging completion of script
Add-LogMessage -message "Ending script"