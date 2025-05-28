## Reviewed 13/02/2025
## Version 1.0
## Template Revision 1.0


#---------- Common Script Variables ----------#
$ScriptName = "BitDefenderInstall"
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

if (Test-Path "C:\Program Files\Bitdefender\Endpoint Security\EPConsole.exe") {
	Write-Output "OK! - Bitdefender installed"
	Exit 0
}

Write-Output "ERROR! - Bitdefender not found"
Exit 1