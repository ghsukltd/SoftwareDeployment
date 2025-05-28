## Reviewed 12/02/2025
## Version 1.0
## Template Revision 1.0


#---------- Common Script Variables ----------#
$ScriptName = "InstallStoreLTSC2021"
$GHSKey = "HKLM:\SOFTWARE\GHS"

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

$app = Get-AppxPackage -AllUsers -Name "Microsoft.WindowsStore"

if ($app) {
    Write-Output "OK! - Found store"
    Exit 0
}

Write-Output "ERROR! - Store not found"
Exit 1