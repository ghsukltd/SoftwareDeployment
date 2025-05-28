# Function to check if a service is running
function Test-ServiceRunning {
    param (
        [string]$serviceName
    )

    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        return $true
    } else {
        return $false
    }
}

# Function to check if a directory exists
function Test-DirectoryExists {
    param (
        [string]$path
    )

    return Test-Path -Path $path -PathType Container
}

# Check if CagService is running
$serviceCheck = Test-ServiceRunning -serviceName "CagService"

# Check if the directories exist
$programFilesCheck = Test-DirectoryExists -path "C:\Program Files (x86)\CentraStage"
$programDataCheck = Test-DirectoryExists -path "C:\ProgramData\CentraStage"

# Evaluate results
if ($serviceCheck -and $programFilesCheck -and $programDataCheck) {
    Write-Output "Detection passed: CagService is running and required directories exist."
    exit 0
} else {
    Write-Output "Detection failed: One or more conditions are not met."
    Write-Output "Service running: $serviceCheck"
    Write-Output "C:\Program Files (x86)\CentraStage exists: $programFilesCheck"
    Write-Output "C:\ProgramData\CentraStage exists: $programDataCheck"
    exit 1
}
