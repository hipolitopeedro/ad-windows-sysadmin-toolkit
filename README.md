# 🛠️ AD & Windows Server SysAdmin Toolkit

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows Server](https://img.shields.io/badge/Windows%20Server-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![Active Directory](https://img.shields.io/badge/Active%20Directory-00599C?style=for-the-badge&logo=microsoft&logoColor=white)

> 🇺🇸 **English:** Collection of PowerShell scripts designed to automate routine **Active Directory (AD DS)** and **Windows Server** administration, security auditing, and server health monitoring.
>
> 🇧🇷 **Português:** Coleção de scripts em PowerShell desenvolvidos para automatizar rotinas de administração do **Active Directory (AD DS)** e **Windows Server**, auditoria de segurança e monitoramento de saúde de servidores.

---

## 📂 Included Scripts / Scripts Inclusos

| Script | Description (EN) | Descrição (PT-BR) |
| :--- | :--- | :--- |
| [`scripts/Get-ADInactiveUsersReport.ps1`](scripts/Get-ADInactiveUsersReport.ps1) | Audits Active Directory for user accounts inactive for `N` days (default: 60), exporting a detailed CSV report for security compliance. | Audita o Active Directory buscando contas de usuários sem logon há `N` dias (padrão: 60) e exporta relatório CSV para conformidade de segurança. |
| [`scripts/New-ADBulkUsersFromCSV.ps1`](scripts/New-ADBulkUsersFromCSV.ps1) | Automates employee onboarding by creating AD accounts in bulk from a CSV file, placing them in target OUs and security groups. | Automatiza o onboarding criando contas do AD em massa a partir de um arquivo CSV, alocando-as nas OUs e grupos de segurança corretos. |
| [`scripts/Get-ADPasswordExpirationReport.ps1`](scripts/Get-ADPasswordExpirationReport.ps1) | Lists enabled users whose passwords expire within a configurable threshold (e.g., 14 days) so IT support can proactively notify them. | Lista usuários ativos cujas senhas irão expirar em breve (ex: 14 dias) para atuação preventiva da equipe de suporte/infra. |
| [`scripts/Invoke-WindowsServerHealthCheck.ps1`](scripts/Invoke-WindowsServerHealthCheck.ps1) | Collects CPU load, RAM usage, disk space alerts, critical Windows services status (`ADWS`, `DNS`, `NTDS`, `Netlogon`, `DFSR`), and recent System Event Log errors. | Coleta uso de CPU, memória RAM, alertas de espaço em disco, status de serviços críticos do Windows Server e erros recentes no Event Viewer. |
| [`templates/users-onboarding-sample.csv`](templates/users-onboarding-sample.csv) | Sample CSV template for bulk user provisioning. | Modelo de arquivo CSV para criação de usuários em lote. |

---

## 🚀 Usage Examples / Exemplos de Uso

### 1. Inactive AD Users Audit / Auditoria de Usuários Inativos
```powershell
# Find enabled accounts with no logon in the last 90 days
.\scripts\Get-ADInactiveUsersReport.ps1 -InactiveDays 90 -ExportPath "C:\Reports\InactiveUsers.csv"
```

### 2. Bulk User Onboarding / Criação de Usuários em Massa
```powershell
# Run in Dry-Run (-WhatIf) mode first to validate changes safely
.\scripts\New-ADBulkUsersFromCSV.ps1 -CsvPath ".\templates\users-onboarding-sample.csv" -WhatIf

# Execute provisioning
.\scripts\New-ADBulkUsersFromCSV.ps1 -CsvPath ".\templates\users-onboarding-sample.csv"
```

### 3. Password Expiration Check / Relatório de Expiração de Senhas
```powershell
.\scripts\Get-ADPasswordExpirationReport.ps1 -DaysThreshold 14 -ExportPath "C:\Reports\ExpiringPasswords.csv"
```

### 4. Windows Server Health Check / Health Check de Servidor
```powershell
.\scripts\Invoke-WindowsServerHealthCheck.ps1 -DiskFreeThresholdPercent 15
```

---

## 🔒 Security Best Practices / Boas Práticas de Segurança

- **No Hardcoded Credentials:** None of the scripts store passwords, domain names, or internal IPs in plain text.
- **Least Privilege:** Run Active Directory scripts with an account that has delegated permissions only for the target Organizational Units (OUs).
- **Safe Execution:** Provisioning scripts support `-WhatIf` (`SupportsShouldProcess`) to preview actions before modifying directory objects.
