## Reviewed 19/02/2025
## Version 1.1
## Template Revision 1.0
# Detect .Net Versions below 8


#---------- Script ----------#

$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$oldRuntimes = foreach ($path in $registryPaths) {
    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
        ($_.DisplayName -match "Microsoft \.NET Runtime.+" -or
         $_.DisplayName -match "Microsoft Windows Desktop Runtime.+") -and
         ($_.DisplayName -notmatch "^.+8(\.|$)")
    }
}

if ($oldRuntimes.Count -eq 0) {
    Write-Output "OK!"
    Exit 0
} else {
    Write-Output "ERROR! - Found old versions"
    Exit 1
}