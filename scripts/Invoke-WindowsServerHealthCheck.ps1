<#
.SYNOPSIS
    Performs a health check on a Windows Server (CPU, RAM, Disk Space, Critical Services, Event Logs).
    Realiza diagnóstico de saúde em um Windows Server (CPU, RAM, Disco, Serviços Críticos e Eventos).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$DiskFreeThresholdPercent = 15,

    [Parameter(Mandatory = $false)]
    [string[]]$CriticalServices = @('NTDS', 'ADWS', 'DNS', 'Netlogon', 'DFSR', 'LanmanServer', 'W32Time', 'DhcpServer')
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   WINDOWS SERVER INFRASTRUCTURE HEALTH CHECK" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$OS = Get-CimInstance -ClassName Win32_OperatingSystem
$CPU = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
$Uptime = (Get-Date) - $OS.LastBootUpTime

$TotalRAM_GB = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$FreeRAM_GB  = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
$UsedRAM_Pct = [math]::Round((($TotalRAM_GB - $FreeRAM_GB) / $TotalRAM_GB) * 100, 1)

Write-Host "`n[1] SYSTEM OVERVIEW" -ForegroundColor Yellow
Write-Host "    Hostname    : $env:COMPUTERNAME"
Write-Host "    OS Version  : $($OS.Caption) ($($OS.Version))"
Write-Host "    Uptime      : $($Uptime.Days)d $($Uptime.Hours)h $($Uptime.Minutes)m"
Write-Host "    CPU Load    : $([math]::Round($CPU.Average, 1))%"
Write-Host "    Memory Usage: $($TotalRAM_GB - $FreeRAM_GB) GB / $TotalRAM_GB GB ($UsedRAM_Pct%)"

Write-Host "`n[2] STORAGE & DISK UTILIZATION" -ForegroundColor Yellow
$Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
foreach ($Disk in $Disks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB, 2)
    $FreeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
    $FreePct = if ($Disk.Size -gt 0) { [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 1) } else { 0 }

    $Color = if ($FreePct -lt $DiskFreeThresholdPercent) { "Red" } else { "Green" }
    $Status = if ($FreePct -lt $DiskFreeThresholdPercent) { "LOW SPACE ALERT" } else { "OK" }
    Write-Host "    Drive $($Disk.DeviceID) -> Free: $FreeGB GB / $SizeGB GB ($FreePct%) [$Status]" -ForegroundColor $Color
}

Write-Host "`n[3] INFRASTRUCTURE SERVICES STATUS" -ForegroundColor Yellow
foreach ($SvcName in $CriticalServices) {
    $Svc = Get-Service -Name $SvcName -ErrorAction SilentlyContinue
    if ($null -ne $Svc) {
        $SvcColor = if ($Svc.Status -eq 'Running') { "Green" } else { "Red" }
        Write-Host ("    {0,-16} : {1} ({2})" -f $Svc.Name, $Svc.Status, $Svc.DisplayName) -ForegroundColor $SvcColor
    }
}

Write-Host "`n[4] CRITICAL / ERROR SYSTEM EVENTS (LAST 24H)" -ForegroundColor Yellow
$Yesterday = (Get-Date).AddHours(-24)
$Events = Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 1, 2; StartTime = $Yesterday } -MaxEvents 10 -ErrorAction SilentlyContinue
if ($Events) {
    $Events | Select-Object TimeCreated, Id, ProviderName, @{Name='Message';Expression={$_.Message -replace "\r\n"," "}} | Format-Table -AutoSize
} else {
    Write-Host "    No Critical or Error events in the System log over the last 24 hours." -ForegroundColor Green
}
