#Requires -RunAsAdministrator
<#
.SYNOPSIS
    System Sensing Script for Dell Precision 7540
.DESCRIPTION
    Detects and reports hardware, software, network, and security
    configuration. Outputs a full system profile to the console
    and saves a detailed report to the desktop.
.NOTES
    Run as Administrator in PowerShell 5.1 or later.
#>

$ErrorActionPreference = "SilentlyContinue"
$ReportPath = "$env:USERPROFILE\Desktop\SystemReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-Section {
    param([string]$Title)
    $separator = "=" * 60
    $output = "`n$separator`n  $Title`n$separator"
    Write-Host $output -ForegroundColor Cyan
    Add-Content -Path $ReportPath -Value $output
}

function Write-Info {
    param([string]$Label, [string]$Value)
    $line = "  {0,-30} {1}" -f $Label, $Value
    Write-Host $line
    Add-Content -Path $ReportPath -Value $line
}

Write-Host "`n  SYSTEM SENSING REPORT" -ForegroundColor Green
Write-Host "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Set-Content -Path $ReportPath -Value "SYSTEM SENSING REPORT`nGenerated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Hardware
Write-Section "HARDWARE"
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor
$gpu = Get-CimInstance Win32_VideoController
$disk = Get-CimInstance Win32_DiskDrive
$battery = Get-CimInstance Win32_Battery

Write-Info "Manufacturer:" $cs.Manufacturer
Write-Info "Model:" $cs.Model
Write-Info "Serial Number:" $bios.SerialNumber
Write-Info "BIOS Version:" $bios.SMBIOSBIOSVersion
Write-Info "Processor:" $cpu.Name
Write-Info "Cores / Threads:" "$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)"
Write-Info "RAM:" "$([math]::Round($cs.TotalPhysicalMemory / 1GB, 1)) GB"
Write-Info "GPU:" $gpu.Name
Write-Info "GPU Driver:" $gpu.DriverVersion

foreach ($d in $disk) {
    Write-Info "Disk:" "$($d.Model) ($([math]::Round($d.Size / 1GB, 0)) GB)"
}

if ($battery) {
    Write-Info "Battery Status:" $battery.Status
    Write-Info "Battery Charge:" "$($battery.EstimatedChargeRemaining)%"
}

# Operating System
Write-Section "OPERATING SYSTEM"
$os = Get-CimInstance Win32_OperatingSystem

Write-Info "OS:" $os.Caption
Write-Info "Version:" $os.Version
Write-Info "Build:" $os.BuildNumber
Write-Info "Architecture:" $os.OSArchitecture
Write-Info "Install Date:" $os.InstallDate.ToString("yyyy-MM-dd")
Write-Info "Last Boot:" $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")
Write-Info "Uptime:" "$([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)) hours"

# Network
Write-Section "NETWORK"
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $adapters) {
    $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
    Write-Info "Adapter:" $adapter.Name
    Write-Info "  MAC Address:" $adapter.MacAddress
    Write-Info "  IP Address:" $ipConfig.IPAddress
    Write-Info "  Speed:" "$($adapter.LinkSpeed)"
}

$publicIP = try { (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5) } catch { "Unavailable" }
Write-Info "Public IP:" $publicIP

$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object -First 1
Write-Info "DNS Servers:" ($dns.ServerAddresses -join ", ")

# Security Status
Write-Section "SECURITY STATUS"
$defender = Get-MpComputerStatus

Write-Info "Antivirus Enabled:" $defender.AntivirusEnabled
Write-Info "Real-Time Protection:" $defender.RealTimeProtectionEnabled
Write-Info "Antivirus Signatures:" $defender.AntivirusSignatureLastUpdated.ToString("yyyy-MM-dd")
Write-Info "Firewall (Domain):" (Get-NetFirewallProfile -Name Domain).Enabled
Write-Info "Firewall (Private):" (Get-NetFirewallProfile -Name Private).Enabled
Write-Info "Firewall (Public):" (Get-NetFirewallProfile -Name Public).Enabled

$bitlocker = Get-BitLockerVolume -MountPoint "C:"
Write-Info "BitLocker (C:):" $bitlocker.ProtectionStatus

$secBoot = Confirm-SecureBootUEFI
Write-Info "Secure Boot:" $secBoot

$tpm = Get-Tpm
Write-Info "TPM Present:" $tpm.TpmPresent
Write-Info "TPM Ready:" $tpm.TpmReady
Write-Info "TPM Version:" (Get-CimInstance -Namespace "root\cimv2\Security\MicrosoftTpm" -ClassName Win32_Tpm).SpecVersion

# Windows Update
Write-Section "WINDOWS UPDATE"
$hotfixes = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5

foreach ($hf in $hotfixes) {
    Write-Info "$($hf.HotFixID):" "Installed $($hf.InstalledOn.ToString('yyyy-MM-dd'))"
}

# User Accounts
Write-Section "USER ACCOUNTS"
$users = Get-LocalUser

foreach ($user in $users) {
    $status = if ($user.Enabled) { "Enabled" } else { "Disabled" }
    Write-Info "$($user.Name):" "$status (Last logon: $($user.LastLogon))"
}

$admins = Get-LocalGroupMember -Group "Administrators"
Write-Info "Administrators:" ($admins.Name -join ", ")

# Installed Software (Top 20)
Write-Section "INSTALLED SOFTWARE (RECENT)"
$software = Get-CimInstance Win32_Product | Sort-Object InstallDate -Descending | Select-Object -First 20

foreach ($app in $software) {
    Write-Info "$($app.Name):" "v$($app.Version)"
}

# Running Services
Write-Section "RUNNING SERVICES (NOTABLE)"
$notableServices = @("WinDefend", "mpssvc", "BITS", "wuauserv", "Dnscache", "EventLog", "TermService", "WinRM", "sshd")
foreach ($svcName in $notableServices) {
    $svc = Get-Service -Name $svcName
    if ($svc) {
        Write-Info "$($svc.DisplayName):" $svc.Status
    }
}

# Open Ports
Write-Section "LISTENING PORTS"
$listeners = Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object -First 15

foreach ($l in $listeners) {
    $proc = Get-Process -Id $l.OwningProcess
    Write-Info "Port $($l.LocalPort):" "$($proc.ProcessName) (PID: $($l.OwningProcess))"
}

# Summary
Write-Section "REPORT COMPLETE"
Write-Info "Report saved to:" $ReportPath
Write-Host "`n  Done. Review the report on your Desktop.`n" -ForegroundColor Green
