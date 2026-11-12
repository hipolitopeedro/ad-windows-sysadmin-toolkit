<#
.SYNOPSIS
    Provisions Active Directory user accounts in bulk from a CSV file.
    Cria contas de usuário no Active Directory em lote a partir de um arquivo CSV.

.DESCRIPTION
    EN: Reads user onboarding records from a CSV file, checks for existing SamAccountNames,
        creates the AD user in the target OU, assigns group memberships, and requires password
        change at next logon. Supports -WhatIf for dry-run validation.
    PT: Lê registros de onboarding de um CSV, verifica duplicidade de SamAccountName, cria o
        usuário na OU de destino, adiciona aos grupos de segurança e exige troca de senha no
        primeiro logon. Suporta -WhatIf para simulação segura.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\Onboarding_$(Get-Date -Format 'yyyyMMdd').log"
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogPath -Value $Entry
    switch ($Level) {
        "INFO"  { Write-Host $Entry -ForegroundColor Cyan }
        "OK"    { Write-Host $Entry -ForegroundColor Green }
        "WARN"  { Write-Host $Entry -ForegroundColor Yellow }
        "ERROR" { Write-Host $Entry -ForegroundColor Red }
    }
}

Import-Module ActiveDirectory -ErrorAction Stop
$Users = Import-Csv -Path $CsvPath

foreach ($User in $Users) {
    $Username = $User.SamAccountName.Trim()
    $FullName = "$($User.FirstName.Trim()) $($User.LastName.Trim())"

    $Existing = Get-ADUser -Filter "SamAccountName -eq '$Username'" -ErrorAction SilentlyContinue
    if ($Existing) {
        Write-Log "User '$Username' already exists in Active Directory. Skipping." -Level "WARN"
        continue
    }

    if ($PSCmdlet.ShouldProcess("$FullName ($Username)", "Create Active Directory User in $($User.TargetOU)")) {
        try {
            # Generate a strong temporary password
            $RandomBytes = New-Object byte[] 12
            [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($RandomBytes)
            $TempPasswordPlain = [Convert]::ToBase64String($RandomBytes) + "!Aa1"
            $SecurePassword = ConvertTo-SecureString $TempPasswordPlain -AsPlainText -Force

            $NewUserParams = @{
                Name                  = $FullName
                GivenName             = $User.FirstName.Trim()
                Surname               = $User.LastName.Trim()
                DisplayName           = $FullName
                SamAccountName        = $Username
                UserPrincipalName     = "$Username@$($User.DomainSuffix.Trim())"
                EmailAddress          = "$Username@$($User.DomainSuffix.Trim())"
                Title                 = $User.Title
                Department            = $User.Department
                Path                  = $User.TargetOU
                AccountPassword       = $SecurePassword
                Enabled               = $true
                ChangePasswordAtLogon = $true
                ErrorAction           = 'Stop'
            }

            New-ADUser @NewUserParams
            Write-Log "Created user '$Username' ($FullName) in OU '$($User.TargetOU)'." -Level "OK"

            if (-not [string]::IsNullOrWhiteSpace($User.Groups)) {
                $Groups = $User.Groups -split ';'
                foreach ($Group in $Groups) {
                    Add-ADGroupMember -Identity $Group.Trim() -Members $Username -ErrorAction Stop
                    Write-Log "Added '$Username' to group '$($Group.Trim())'." -Level "INFO"
                }
            }
        }
        catch {
            Write-Log "Failed to provision '$Username': $($_.Exception.Message)" -Level "ERROR"
        }
    }
}
