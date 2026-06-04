#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Network Configuration and Hotspot Fix
.DESCRIPTION
    Diagnoses and repairs WiFi/hotspot issues, configures DNS
    for security, and sets up network hardening.
    Designed for Dell Precision 7540.
.NOTES
    Run as Administrator.
#>

$ErrorActionPreference = "SilentlyContinue"
$LogPath = "$env:USERPROFILE\Desktop\NetworkLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Log {
    param([string]$Message, [string]$Color = "White")
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $line
}

Set-Content -Path $LogPath -Value "NETWORK CONFIGURATION LOG`nStarted: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# ============================================================
Log "=== WIFI ADAPTER DIAGNOSTICS ===" "Cyan"
# ============================================================

$wifiAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match "Wi-Fi|Wireless|WLAN" }

if ($wifiAdapter) {
    Log "WiFi adapter found: $($wifiAdapter.InterfaceDescription)" "Green"
    Log "  Status: $($wifiAdapter.Status)" "White"
    Log "  MAC: $($wifiAdapter.MacAddress)" "White"
    Log "  Speed: $($wifiAdapter.LinkSpeed)" "White"
} else {
    Log "No WiFi adapter detected." "Red"
}

# ============================================================
Log "`n=== HOTSPOT REPAIR ===" "Cyan"
# ============================================================

Log "Resetting WiFi adapter..." "Yellow"
if ($wifiAdapter) {
    Disable-NetAdapter -Name $wifiAdapter.Name -Confirm:$false
    Start-Sleep -Seconds 3
    Enable-NetAdapter -Name $wifiAdapter.Name -Confirm:$false
    Start-Sleep -Seconds 5
    Log "WiFi adapter reset complete." "Green"
}

Log "Resetting Winsock catalog..." "Yellow"
netsh winsock reset 2>&1 | Out-Null
Log "Winsock reset complete." "Green"

Log "Resetting TCP/IP stack..." "Yellow"
netsh int ip reset 2>&1 | Out-Null
Log "TCP/IP reset complete." "Green"

Log "Flushing DNS cache..." "Yellow"
ipconfig /flushdns 2>&1 | Out-Null
Log "DNS cache flushed." "Green"

Log "Releasing and renewing IP..." "Yellow"
ipconfig /release 2>&1 | Out-Null
Start-Sleep -Seconds 2
ipconfig /renew 2>&1 | Out-Null
Log "IP renewed." "Green"

Log "Checking Mobile Hotspot service..." "Yellow"
$hotspotService = Get-Service -Name "icssvc" -ErrorAction SilentlyContinue
if ($hotspotService) {
    Restart-Service -Name "icssvc" -Force
    Set-Service -Name "icssvc" -StartupType Automatic
    Log "Mobile Hotspot service restarted and set to automatic." "Green"
} else {
    Log "Mobile Hotspot service not found." "Yellow"
}

Log "Resetting Mobile Hotspot configuration..." "Yellow"
$hotspotRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\icssvc\Settings"
if (Test-Path $hotspotRegPath) {
    Log "Hotspot registry path found. Resetting..." "Yellow"
    Set-ItemProperty -Path $hotspotRegPath -Name "PeerlessTimeoutEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
}

Log "Verifying hosted network support..." "Yellow"
$hostedCheck = netsh wlan show drivers 2>&1
if ($hostedCheck -match "Hosted network supported\s*:\s*Yes") {
    Log "Hosted network is supported." "Green"
} else {
    Log "Hosted network may not be supported by this adapter." "Yellow"
}

# ============================================================
Log "`n=== SECURE DNS CONFIGURATION ===" "Cyan"
# ============================================================

Log "Setting DNS to Cloudflare (1.1.1.1) and Google (8.8.8.8)..." "Yellow"
$activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($adapter in $activeAdapters) {
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @("1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4")
    Log "  DNS set for: $($adapter.Name)" "Green"
}

Log "Enabling DNS over HTTPS..." "Yellow"
$dohPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
Set-ItemProperty -Path $dohPath -Name "EnableAutoDoh" -Value 2 -Type DWord -ErrorAction SilentlyContinue
Log "DNS over HTTPS enabled (requires Windows 11 or Windows 10 21H2+)." "Green"

# ============================================================
Log "`n=== NETWORK HARDENING ===" "Cyan"
# ============================================================

Log "Disabling NetBIOS over TCP/IP..." "Yellow"
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
Get-ChildItem $regPath | ForEach-Object {
    Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 2 -Type DWord
}
Log "NetBIOS disabled." "Green"

Log "Disabling LLMNR..." "Yellow"
$llmnrPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (-not (Test-Path $llmnrPath)) { New-Item -Path $llmnrPath -Force | Out-Null }
Set-ItemProperty -Path $llmnrPath -Name "EnableMulticast" -Value 0 -Type DWord
Log "LLMNR disabled." "Green"

Log "Disabling WPAD..." "Yellow"
$wpadPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad"
if (-not (Test-Path $wpadPath)) { New-Item -Path $wpadPath -Force | Out-Null }
Set-ItemProperty -Path $wpadPath -Name "WpadOverride" -Value 1 -Type DWord
Log "WPAD disabled." "Green"

# ============================================================
Log "`n=== NETWORK STATUS ===" "Cyan"
# ============================================================

Log "Current network configuration:" "White"
$activeAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($adapter in $activeAdapters) {
    $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
    $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
    Log "  $($adapter.Name): $($ip.IPAddress) | DNS: $($dns.ServerAddresses -join ', ')" "Green"
}

$connectivity = Test-NetConnection -ComputerName "1.1.1.1" -WarningAction SilentlyContinue
if ($connectivity.PingSucceeded) {
    Log "Internet connectivity: OK ($($connectivity.RemoteAddress))" "Green"
} else {
    Log "Internet connectivity: FAILED" "Red"
}

Log "`n=== CONFIGURATION COMPLETE ===" "Cyan"
Log "Log saved to: $LogPath" "Green"
Log "A restart is recommended to fully apply network changes." "Yellow"
