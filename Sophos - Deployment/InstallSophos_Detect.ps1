## Sophos Install UUID Detection
## Reviewed 21/02/2025
## Script Version 2.0
## Template Revision 1.1

#---------- Common Script Variables ----------#
$expectedTenantUUID = "aaaa"
$registryPath = "HKLM:\SOFTWARE\Sophos\Management\Policy\Authority"
$MCSendpoint = "Sophos\Management Communications System\Endpoint\McsClient.exe"

#---------- Code ----------#

$programFilesPath = if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { ${env:ProgramFiles(x86)} } else { $env:ProgramFiles }
$MCSPath = Join-Path -Path $programFilesPath -ChildPath $MCSendpoint

if (Test-Path $MCSPath) {
    $childKeys = Get-ChildItem -Path $registryPath
    foreach ($childKey in $childKeys) {
        # Construct the full path to the current key
        $fullPath = Join-Path -Path $registryPath -ChildPath $childKey.PSChildName
        # Attempt to read the target value
        $tenantIdValue = (Get-ItemProperty -Path $fullPath -Name "tenantId" -ErrorAction SilentlyContinue).tenantId
        if ($tenantIdValue -eq $expectedTenantUUID) {
            Write-Output "OK! - Found install"
            Exit 0
        }
    }
}

Write-Output "ERROR! - Install not found"
Exit 1