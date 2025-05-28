## Intune Detection Script - PaperCut Hive (User Install)
## Reviewed 13/03/2025
## Version 1.4
## Template Revision 1.0

$HiveExe = "$($ENV:LOCALAPPDATA)\Programs\PaperCut Hive\pc-print-client-service.exe"
$HiveFolder = "$($ENV:LOCALAPPDATA)\Programs\PaperCut Hive\"

# Check if the executable exists
$ExeExists = Test-Path $HiveExe

# Check if at least one 'v*' build folder exists
$BuildFolders = Get-ChildItem -Path $HiveFolder -Directory -Filter "v*" -ErrorAction SilentlyContinue
$BuildFolderExists = $BuildFolders.Count -gt 0

# Check if the process is running for the current user by checking the path
$ProcessRunning = Get-Process -Name "pc-print-client-service" -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $HiveExe }

# Check if the application is set to start with Windows
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$StartupTask = Get-ItemProperty -Path $RegistryPath -Name "(Default)" -ErrorAction SilentlyContinue
$StartupExists = $StartupTask -and ($StartupTask."(default)".Trim('"') -eq $HiveExe)

# Detection logic with detailed output
if (-not $ExeExists) {
    Write-Output "ERROR! - PaperCut Hive executable not found: $HiveExe"
    Exit 1
}

if (-not $BuildFolderExists) {
    Write-Output "ERROR! - No PaperCut Hive build folders found in $HiveFolder"
    Exit 1
}

if (-not $ProcessRunning) {
    Write-Output "ERROR! - PaperCut Hive process is not running for the current user"
    Exit 1
}

if (-not $StartupExists) {
    Write-Output "ERROR! - PaperCut Hive is not set to start with Windows"
    Exit 1
}

Write-Output "OK! - PaperCut Hive detected, build folder found, process running, and startup entry exists"
Exit 0