## Reviewed 13/05/2025
## Version 2.0
## Template Revision 1.0
# Detect_QualysAgent

#---------- Common Script Variables ----------#
$activationid = ""
$customerid = ""

#---------- Functions ----------#

# Detection Script for Qualys Cloud Agent
$regPath = "HKLM:\SOFTWARE\Qualys"
$filePath = "C:\Program Files\Qualys\QualysAgent\QualysAgent.exe"
$serviceName = "Qualys Cloud Agent"

# Check registry values
try {
    $regActivationID = Get-ItemProperty -Path $regPath -Name "ActivationID" -ErrorAction Stop | Select-Object -ExpandProperty ActivationID
    $regCustomerID = Get-ItemProperty -Path $regPath -Name "CustomerID" -ErrorAction Stop | Select-Object -ExpandProperty CustomerID
} catch {
    Write-Output "Registry keys don't exist"
    Exit 1
}

if ($regActivationID -ne $activationid -or $regCustomerID -ne $customerid) {
    Write-Output "Registry keys don't match expected"
    Exit 1
}

# Check if file exists
if (-not (Test-Path -Path $filePath)) {
    Write-Output "File path doesn't exist"
    Exit 1
}

# Check if service is running
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($null -eq $service -or $service.Status -ne 'Running') {
    Write-Output "Service doesn't exist, or isn't running"
    Exit 1
}

Write-Output "OK! - Found install"
Exit 0