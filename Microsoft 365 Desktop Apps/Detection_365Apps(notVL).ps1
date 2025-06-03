## Reviewed 03/06/2025
## Version 1.0
## Template Revision 1.0

# Detection Script for Microsoft 365 Apps (Click-to-Run)

# Define registry path for Office Click-to-Run installations
$officeC2RRegPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

try {
    $config = Get-ItemProperty -Path $officeC2RRegPath -ErrorAction Stop

    # Check for specific product release
    if ($config.ProductReleaseIds -match "O365ProPlusRetail|O365BusinessRetail|O365BusinessEEANoTeamsRetail|O365ProPlusEEANoTeamsRetail") {
        Write-Output "OK! - Found install"
        exit 0
    } else {
        Write-Output "ERROR! - Install not found (IDs aren't right!)"
        exit 1
    }
} catch {
    Write-Output "ERROR! - Install not found"
    exit 1
}