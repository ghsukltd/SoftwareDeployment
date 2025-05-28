## Intune Detection Script - PaperCut Hive
## Reviewed 13/03/2025
## Version 1.3
## Template Revision 1.0

$HiveExe = "C:\Program Files\PaperCut Hive\pc-edgenode-service.exe"
$HiveFolder = "C:\Program Files\PaperCut Hive\"

# Check if the executable exists
$ExeExists = Test-Path $HiveExe

# Check if at least one 'v*' build folder exists
$BuildFolders = Get-ChildItem -Path $HiveFolder -Directory -Filter "v*" -ErrorAction SilentlyContinue
$BuildFolderExists = $BuildFolders.Count -gt 0

# Check if the service exists and is running
$Service = Get-Service -Name "pc-edgenode-service" -ErrorAction SilentlyContinue
$ServiceExists = $null -ne $Service
$ServiceRunning = $ServiceExists -and $Service.Status -eq 'Running'

# Detection logic with detailed output
if (-not $ExeExists) {
    Write-Output "ERROR! - PaperCut Hive executable not found: $HiveExe"
    Exit 1
}

if (-not $BuildFolderExists) {
    Write-Output "ERROR! - No PaperCut Hive date folders found in $HiveFolder"
    Exit 1
}

if (-not $ServiceExists) {
    Write-Output "ERROR! - PaperCut Hive service not installed"
    Exit 1
}

if (-not $ServiceRunning) {
    Write-Output "ERROR! - PaperCut Hive service installed but not running"
    Exit 1
}

Write-Output "OK! - PaperCut Hive detected, date folders found, and service running"
Exit 0