<#
.SYNOPSIS
    Audits Active Directory for inactive user accounts and exports a CSV report.
    Audita o Active Directory em busca de contas inativas e exporta relatório CSV.

.DESCRIPTION
    EN: Queries Active Directory for enabled user accounts whose LastLogonDate is older than
        the specified threshold (or who have never logged on) and exports the findings to CSV.
    PT: Consulta o Active Directory buscando contas ativas cujo último logon seja anterior ao
        limite definido (ou que nunca fizeram logon) e exporta o resultado para CSV.

.PARAMETER InactiveDays
    Number of days without logon to consider an account inactive (Default: 60).

.PARAMETER SearchBase
    Optional Distinguished Name (DN) of an Organizational Unit (OU) to scope the search.

.PARAMETER ExportPath
    File path for the generated CSV report.

.EXAMPLE
    .\Get-ADInactiveUsersReport.ps1 -InactiveDays 90 -ExportPath "C:\Reports\AD_Inactive_Users.csv"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3650)]
    [int]$InactiveDays = 60,

    [Parameter(Mandatory = $false)]
    [string]$SearchBase,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath = ".\AD_InactiveUsers_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
)

Begin {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Throw "ActiveDirectory module is not installed. Install RSAT (Remote Server Administration Tools) before running this script."
    }
    Import-Module ActiveDirectory -ErrorAction Stop

    $CutoffDate = (Get-Date).AddDays(-$InactiveDays)
    Write-Host "[INFO] Auditing enabled AD accounts inactive since $($CutoffDate.ToString('yyyy-MM-dd')) ($InactiveDays days)..." -ForegroundColor Cyan
}

Process {
    $ADParams = @{
        Filter     = { Enabled -eq $true -and (LastLogonDate -lt $CutoffDate -or -not (LastLogonDate -like "*")) }
        Properties = @('DisplayName', 'EmailAddress', 'Department', 'Title', 'LastLogonDate', 'WhenCreated', 'PasswordLastSet', 'DistinguishedName')
    }

    if ($PSBoundParameters.ContainsKey('SearchBase') -and -not [string]::IsNullOrWhiteSpace($SearchBase)) {
        $ADParams['SearchBase'] = $SearchBase
    }

    $InactiveUsers = Get-ADUser @ADParams | Select-Object `
        SamAccountName,
        DisplayName,
        EmailAddress,
        Department,
        Title,
        @{Name = 'LastLogonDate'; Expression = { if ($_.LastLogonDate) { $_.LastLogonDate.ToString('yyyy-MM-dd HH:mm') } else { 'Never' } } },
        @{Name = 'DaysInactive'; Expression = { if ($_.LastLogonDate) { ((Get-Date) - $_.LastLogonDate).Days } else { ((Get-Date) - $_.WhenCreated).Days } } },
        @{Name = 'WhenCreated'; Expression = { $_.WhenCreated.ToString('yyyy-MM-dd') } },
        DistinguishedName | Sort-Object DaysInactive -Descending

    $Count = ($InactiveUsers | Measure-Object).Count
    Write-Host "[OK] Found $Count inactive account(s)." -ForegroundColor Green

    if ($Count -gt 0) {
        $ExportDir = Split-Path -Path $ExportPath -Parent
        if ($ExportDir -and -not (Test-Path -Path $ExportDir)) {
            New-Item -ItemType Directory -Path $ExportDir -Force | Out-Null
        }

        $InactiveUsers | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        Write-Host "[OK] Report exported to: $ExportPath" -ForegroundColor Green
    }
}
