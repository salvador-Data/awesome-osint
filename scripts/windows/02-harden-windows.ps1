#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 10/11 Hardening Script (10/10 Maximum)
.DESCRIPTION
    Applies comprehensive security hardening to a Windows system.
    Covers firewall, Defender, attack surface reduction, privacy,
    remote access, SMB, PowerShell, audit policies, and more.
    Designed for Dell Precision 7540 running Windows 10/11.
.NOTES
    Run as Administrator. Review each section before running.
    Creates a restore point before making changes.
#>

$ErrorActionPreference = "Stop"
$LogPath = "$env:USERPROFILE\Desktop\HardeningLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $line
}

function Log-Success { param([string]$Msg) Log $Msg "Green" }
function Log-Action  { param([string]$Msg) Log $Msg "Yellow" }
function Log-Section { param([string]$Msg) Log "`n=== $Msg ===" "Cyan" }

Set-Content -Path $LogPath -Value "WINDOWS HARDENING LOG`nStarted: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

Log-Section "CREATING RESTORE POINT"
try {
    Checkpoint-Computer -Description "Pre-Hardening Restore Point" -RestorePointType MODIFY_SETTINGS
    Log-Success "Restore point created."
} catch {
    Log "Restore point skipped (may already exist today)." "Yellow"
}

# ============================================================
Log-Section "WINDOWS DEFENDER CONFIGURATION"
# ============================================================

Log-Action "Enabling real-time protection..."
Set-MpPreference -DisableRealtimeMonitoring $false

Log-Action "Enabling cloud-delivered protection..."
Set-MpPreference -MAPSReporting Advanced
Set-MpPreference -SubmitSamplesConsent SendAllSamples

Log-Action "Enabling potentially unwanted app blocking..."
Set-MpPreference -PUAProtection Enabled

Log-Action "Enabling network protection..."
Set-MpPreference -EnableNetworkProtection Enabled

Log-Action "Enabling controlled folder access..."
Set-MpPreference -EnableControlledFolderAccess Enabled

Log-Action "Setting scan schedule (daily at 2 AM)..."
Set-MpPreference -ScanScheduleDay Everyday
Set-MpPreference -ScanScheduleTime 02:00:00

Log-Action "Enabling behavior monitoring..."
Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -DisableIOAVProtection $false
Set-MpPreference -DisableScriptScanning $false

Log-Success "Defender hardened."

# ============================================================
Log-Section "ATTACK SURFACE REDUCTION RULES"
# ============================================================

$asrRules = @{
    "BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550" = "Block executable content from email and webmail"
    "D4F940AB-401B-4EFC-AADC-AD5F3C50688A" = "Block Office apps from creating child processes"
    "3B576869-A4EC-4529-8536-B80A7769E899" = "Block Office apps from creating executable content"
    "75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84" = "Block Office apps from injecting into other processes"
    "D3E037E1-3EB8-44C8-A917-57927947596D" = "Block JavaScript/VBScript from launching downloaded content"
    "5BEB7EFE-FD9A-4556-801D-275E5FFC04CC" = "Block execution of potentially obfuscated scripts"
    "92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B" = "Block Win32 API calls from Office macros"
    "01443614-CD74-433A-B99E-2ECDC07BFC25" = "Block executable files unless they meet criteria"
    "C1DB55AB-C21A-4637-BB3F-A12568109D35" = "Block untrusted/unsigned processes from USB"
    "9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2" = "Block credential stealing from LSASS"
    "D1E49AAC-8F56-4280-B9BA-993A6D77406C" = "Block process creations from PSExec and WMI"
    "B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4" = "Block untrusted programs from removable drives"
    "26190899-1602-49E8-8B27-EB1D0A1CE869" = "Block Office from creating child processes"
    "7674BA52-37EB-4A4F-A9A1-F0F9A1619A2C" = "Block Adobe Reader from creating child processes"
    "E6DB77E5-3DF2-4CF1-B95A-636979351E5B" = "Block persistence through WMI event subscription"
}

foreach ($rule in $asrRules.GetEnumerator()) {
    Log-Action "Enabling ASR: $($rule.Value)..."
    Add-MpPreference -AttackSurfaceReductionRules_Ids $rule.Key -AttackSurfaceReductionRules_Actions Enabled
}

Log-Success "All ASR rules enabled."

# ============================================================
Log-Section "FIREWALL HARDENING"
# ============================================================

Log-Action "Enabling all firewall profiles..."
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True

Log-Action "Setting default deny inbound..."
Set-NetFirewallProfile -Profile Domain, Public, Private -DefaultInboundAction Block

Log-Action "Allowing outbound by default..."
Set-NetFirewallProfile -Profile Domain, Public, Private -DefaultOutboundAction Allow

Log-Action "Enabling firewall logging..."
Set-NetFirewallProfile -Profile Domain, Public, Private -LogAllowed True -LogBlocked True -LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" -LogMaxSizeKilobytes 32767

Log-Success "Firewall hardened."

# ============================================================
Log-Section "DISABLE UNNECESSARY SERVICES"
# ============================================================

$servicesToDisable = @(
    @{ Name = "RemoteRegistry";   Desc = "Remote Registry" },
    @{ Name = "lfsvc";            Desc = "Geolocation Service" },
    @{ Name = "MapsBroker";       Desc = "Downloaded Maps Manager" },
    @{ Name = "SharedAccess";     Desc = "Internet Connection Sharing" },
    @{ Name = "WMPNetworkSvc";    Desc = "Windows Media Player Sharing" },
    @{ Name = "XblAuthManager";   Desc = "Xbox Live Auth Manager" },
    @{ Name = "XblGameSave";      Desc = "Xbox Live Game Save" },
    @{ Name = "XboxNetApiSvc";    Desc = "Xbox Live Networking" },
    @{ Name = "DiagTrack";        Desc = "Connected User Experiences and Telemetry" },
    @{ Name = "dmwappushservice"; Desc = "WAP Push Message Routing" },
    @{ Name = "RetailDemo";       Desc = "Retail Demo Service" }
)

foreach ($svc in $servicesToDisable) {
    $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
    if ($service) {
        Log-Action "Disabling $($svc.Desc)..."
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc.Name -StartupType Disabled
    }
}

Log-Success "Unnecessary services disabled."

# ============================================================
Log-Section "REMOTE ACCESS LOCKDOWN"
# ============================================================

Log-Action "Disabling Remote Desktop..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1 -Type DWord

Log-Action "Disabling Remote Assistance..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0 -Type DWord

Log-Action "Disabling WinRM..."
try {
    Disable-PSRemoting -Force
} catch {
    Log "WinRM already disabled or not configured." "Yellow"
}

Log-Success "Remote access locked down."

# ============================================================
Log-Section "SMB HARDENING"
# ============================================================

Log-Action "Disabling SMBv1..."
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

Log-Action "Requiring SMB signing..."
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force

Log-Action "Enabling SMB encryption..."
Set-SmbServerConfiguration -EncryptData $true -Force

Log-Success "SMB hardened."

# ============================================================
Log-Section "PRIVACY AND TELEMETRY"
# ============================================================

$privacyKeys = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0 },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 1 },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Value = 0 },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled"; Value = 0 },
    @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled"; Value = 0 },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0 },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsConsumerFeatures"; Value = 1 }
)

foreach ($key in $privacyKeys) {
    Log-Action "Setting $($key.Name)..."
    if (-not (Test-Path $key.Path)) {
        New-Item -Path $key.Path -Force | Out-Null
    }
    Set-ItemProperty -Path $key.Path -Name $key.Name -Value $key.Value -Type DWord
}

Log-Success "Privacy and telemetry restricted."

# ============================================================
Log-Section "POWERSHELL SECURITY"
# ============================================================

Log-Action "Setting PowerShell execution policy to RemoteSigned..."
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

Log-Action "Enabling PowerShell script block logging..."
$psLogPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
if (-not (Test-Path $psLogPath)) { New-Item -Path $psLogPath -Force | Out-Null }
Set-ItemProperty -Path $psLogPath -Name "EnableScriptBlockLogging" -Value 1 -Type DWord

Log-Action "Enabling PowerShell module logging..."
$psModPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
if (-not (Test-Path $psModPath)) { New-Item -Path $psModPath -Force | Out-Null }
Set-ItemProperty -Path $psModPath -Name "EnableModuleLogging" -Value 1 -Type DWord

Log-Action "Enabling PowerShell transcription..."
$psTransPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"
if (-not (Test-Path $psTransPath)) { New-Item -Path $psTransPath -Force | Out-Null }
Set-ItemProperty -Path $psTransPath -Name "EnableTranscripting" -Value 1 -Type DWord
Set-ItemProperty -Path $psTransPath -Name "OutputDirectory" -Value "$env:USERPROFILE\Documents\PSTranscripts" -Type String

Log-Success "PowerShell security configured."

# ============================================================
Log-Section "AUDIT POLICIES"
# ============================================================

$auditPolicies = @(
    "Logon/Logoff:Logon",
    "Logon/Logoff:Logoff",
    "Account Logon:Credential Validation",
    "Account Management:User Account Management",
    "Object Access:File System",
    "Policy Change:Audit Policy Change",
    "Privilege Use:Sensitive Privilege Use",
    "System:Security State Change"
)

foreach ($policy in $auditPolicies) {
    $parts = $policy -split ":"
    Log-Action "Enabling audit: $($parts[1])..."
    auditpol /set /subcategory:"$($parts[1])" /success:enable /failure:enable 2>&1 | Out-Null
}

Log-Success "Audit policies configured."

# ============================================================
Log-Section "ADDITIONAL HARDENING"
# ============================================================

Log-Action "Disabling autorun for all drives..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord

Log-Action "Requiring Ctrl+Alt+Del for sign-in..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableCAD" -Value 0 -Type DWord

Log-Action "Hiding last logged-on username..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DontDisplayLastUserName" -Value 1 -Type DWord

Log-Action "Setting account lockout policy (5 attempts, 30 min lockout)..."
net accounts /lockoutthreshold:5 /lockoutduration:30 /lockoutwindow:30 2>&1 | Out-Null

Log-Action "Setting password policy (minimum 12 characters)..."
net accounts /minpwlen:12 /maxpwage:90 /minpwage:1 /uniquepw:5 2>&1 | Out-Null

Log-Action "Disabling guest account..."
net user Guest /active:no 2>&1 | Out-Null

Log-Action "Enabling Windows Update auto-download..."
$wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force | Out-Null }
Set-ItemProperty -Path $wuPath -Name "AUOptions" -Value 3 -Type DWord

Log-Success "Additional hardening complete."

# ============================================================
Log-Section "HARDENING COMPLETE"
# ============================================================

Log "Hardening log saved to: $LogPath" "Green"
Log "A system restart is recommended to apply all changes." "Yellow"
Log "" "White"

$restart = Read-Host "Restart now? (y/n)"
if ($restart -eq "y") {
    Restart-Computer -Force
}
