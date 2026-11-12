<#
.SYNOPSIS
    Lists Active Directory users whose passwords will expire within N days.
    Lista usuários do Active Directory cujas senhas expirarão nos próximos N dias.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 90)]
    [int]$DaysThreshold = 14,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath = ".\AD_ExpiringPasswords_$(Get-Date -Format 'yyyyMMdd').csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

$Users = Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $false } `
    -Properties "DisplayName", "EmailAddress", "Department", "msDS-UserPasswordExpiryTimeComputed"

$Results = foreach ($User in $Users) {
    $ExpiryFileTime = $User."msDS-UserPasswordExpiryTimeComputed"
    if ($ExpiryFileTime -and $ExpiryFileTime -gt 0 -and $ExpiryFileTime -lt [Int64]::MaxValue) {
        $ExpiryDate = [DateTime]::FromFileTime($ExpiryFileTime)
        $DaysRemaining = ($ExpiryDate - (Get-Date)).Days

        if ($DaysRemaining -ge 0 -and $DaysRemaining -le $DaysThreshold) {
            [PSCustomObject]@{
                SamAccountName = $User.SamAccountName
                DisplayName    = $User.DisplayName
                EmailAddress   = $User.EmailAddress
                Department     = $User.Department
                ExpirationDate = $ExpiryDate.ToString("yyyy-MM-dd HH:mm")
                DaysRemaining  = $DaysRemaining
            }
        }
    }
}

$Sorted = $Results | Sort-Object DaysRemaining
$Sorted | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
Write-Host "[OK] Found $(($Sorted | Measure-Object).Count) user(s) with passwords expiring within $DaysThreshold days. Saved to $ExportPath" -ForegroundColor Green
