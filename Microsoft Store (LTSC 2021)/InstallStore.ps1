## Reviewed 14/02/2025
## Version 1.0
## Template Revision 1.0

#---------- Script Variables ----------#
$ScriptName = "InstallStoreLTSC2021"

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
if (Get-ScriptStatus $ScriptName) { exit }

# Logging start of script
Add-LogMessage -message "----------------------------------------------------------"
Add-LogMessage -message "Starting script: $($ScriptName)"

#---------- Script Content Here! ----------#

# Check Windows Version
$winVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ReleaseId
if ($winVersion -lt 19044) {
    Add-LogMessage -message "Error: This pack is for Windows 10 version 21H2 and later" -fout
    Exit
}

# Change to script directory
Set-Location -Path $PSScriptRoot

# Reset Windows Store & Wait 3 Minutes
Add-LogMessage -message "Trying built in reset"
Start-Process -FilePath "c:\Windows\System32\WSReset.exe" -ArgumentList "/i" -Wait
Add-LogMessage -message "Waiting 3 minutes"
Start-Sleep -Seconds 180

# Gather dependencies
$dependencies = @{}
$patterns = @("Microsoft.NET.Native.Framework*1.6*", "Microsoft.NET.Native.Framework*2.2*", "Microsoft.NET.Native.Runtime*1.6*", "Microsoft.NET.Native.Runtime*2.2*", "Microsoft.UI.Xaml.*2.4*", "Microsoft.UI.Xaml.*2.7*", "Microsoft.VCLibs*140*_*")
foreach ($pattern in $patterns) {
    Get-ChildItem $pattern -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -match "x64") { $dependencies["$pattern x64"] = $_.FullName }
        if ($_.Name -match "x86") { $dependencies["$pattern x86"] = $_.FullName }
    }
}

# Define dependency sets
$DepStore = $dependencies.Values -join ","
$storeFile = Get-ChildItem *WindowsStore*.appxbundle -ErrorAction SilentlyContinue
$storeXml = Get-ChildItem *WindowsStore*.xml -ErrorAction SilentlyContinue

# Install Microsoft Store
Add-LogMessage -message "Adding Microsoft Store and its dependencies"
Add-AppxProvisionedPackage -Online -PackagePath $($storeFile.FullName) -LicensePath $($storeXml.FullName)
foreach ($dep in $dependencies.Values) {
    Add-AppxPackage -Path $dep
}
Add-AppxPackage -Path $storeFile.FullName

#---------- Script End ----------#

# Script Success Check
$app = Get-AppxPackage -AllUsers -Name "Microsoft.WindowsStore"
if ($app) {
    # Mark Script as Ran
    Set-ScriptStatus $ScriptName
}

# Logging completion of script
Add-LogMessage -message "Ending script"