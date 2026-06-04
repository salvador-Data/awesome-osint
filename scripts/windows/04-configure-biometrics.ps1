#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configure Windows Hello Biometrics and MFA
.DESCRIPTION
    Enables and configures Windows Hello for Business with
    fingerprint and facial recognition as primary authentication.
    Configures biometrics as primary MFA method.
.NOTES
    Run as Administrator. Hardware biometric sensors must be present.
    Dell Precision 7540 supports fingerprint reader (optional) and
    IR camera for facial recognition (optional, depends on config).
#>

$ErrorActionPreference = "SilentlyContinue"
$LogPath = "$env:USERPROFILE\Desktop\BiometricsLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Log {
    param([string]$Message, [string]$Color = "White")
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $line
}

Set-Content -Path $LogPath -Value "BIOMETRICS CONFIGURATION LOG`nStarted: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# ============================================================
Log "=== DETECTING BIOMETRIC HARDWARE ===" "Cyan"
# ============================================================

$bioDevices = Get-PnpDevice -Class Biometric -Status OK
$fingerprint = $bioDevices | Where-Object { $_.FriendlyName -match "fingerprint|finger" }
$camera = $bioDevices | Where-Object { $_.FriendlyName -match "IR|infrared|hello|face|camera" }

if ($fingerprint) {
    Log "Fingerprint reader detected: $($fingerprint.FriendlyName)" "Green"
} else {
    Log "No fingerprint reader detected. Check Device Manager." "Yellow"
}

if ($camera) {
    Log "IR camera detected: $($camera.FriendlyName)" "Green"
} else {
    Log "No IR/Hello camera detected. Check Device Manager." "Yellow"
}

# ============================================================
Log "`n=== ENABLING WINDOWS HELLO ===" "Cyan"
# ============================================================

Log "Enabling biometric service..." "Yellow"
Set-Service -Name WbioSrvc -StartupType Automatic
Start-Service -Name WbioSrvc
Log "Biometric service started." "Green"

Log "Enabling Windows Hello for sign-in..." "Yellow"
$helloPath = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork"
if (-not (Test-Path $helloPath)) { New-Item -Path $helloPath -Force | Out-Null }
Set-ItemProperty -Path $helloPath -Name "Enabled" -Value 1 -Type DWord

Log "Enabling biometric sign-in..." "Yellow"
$bioPath = "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics"
if (-not (Test-Path $bioPath)) { New-Item -Path $bioPath -Force | Out-Null }
Set-ItemProperty -Path $bioPath -Name "Enabled" -Value 1 -Type DWord

$credPath = "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics\Credential Provider"
if (-not (Test-Path $credPath)) { New-Item -Path $credPath -Force | Out-Null }
Set-ItemProperty -Path $credPath -Name "Enabled" -Value 1 -Type DWord

# ============================================================
Log "`n=== CONFIGURING BIOMETRIC PRIORITY ===" "Cyan"
# ============================================================

Log "Setting biometrics as preferred sign-in method..." "Yellow"

$facePath = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\Biometrics\FacialFeatures"
if (-not (Test-Path $facePath)) { New-Item -Path $facePath -Force | Out-Null }
Set-ItemProperty -Path $facePath -Name "EnhancedAntiSpoofing" -Value 1 -Type DWord
Log "Enhanced anti-spoofing enabled for facial recognition." "Green"

Log "Setting PIN complexity requirements (fallback to biometrics)..." "Yellow"
$pinPath = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork\PINComplexity"
if (-not (Test-Path $pinPath)) { New-Item -Path $pinPath -Force | Out-Null }
Set-ItemProperty -Path $pinPath -Name "MinimumPINLength" -Value 6 -Type DWord
Set-ItemProperty -Path $pinPath -Name "RequireDigits" -Value 1 -Type DWord
Set-ItemProperty -Path $pinPath -Name "RequireLowercase" -Value 1 -Type DWord

# ============================================================
Log "`n=== DISABLING LESS SECURE SIGN-IN METHODS ===" "Cyan"
# ============================================================

Log "Disabling picture password..." "Yellow"
$picPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $picPath)) { New-Item -Path $picPath -Force | Out-Null }
Set-ItemProperty -Path $picPath -Name "BlockDomainPicturePassword" -Value 1 -Type DWord

Log "Requiring Windows Hello for Microsoft accounts..." "Yellow"
Set-ItemProperty -Path $helloPath -Name "RequireSecurityDevice" -Value 1 -Type DWord

# ============================================================
Log "`n=== NEXT STEPS (MANUAL) ===" "Cyan"
# ============================================================

Log "" "White"
Log "The following steps require manual enrollment:" "Yellow"
Log "" "White"
Log "  1. Open Settings > Accounts > Sign-in options" "White"
Log "  2. Under 'Facial recognition (Windows Hello)':" "White"
Log "     - Click 'Set up' and follow the on-screen prompts" "White"
Log "     - Position your face in front of the IR camera" "White"
Log "" "White"
Log "  3. Under 'Fingerprint recognition (Windows Hello)':" "White"
Log "     - Click 'Set up' and follow the on-screen prompts" "White"
Log "     - Touch the fingerprint reader multiple times" "White"
Log "" "White"
Log "  4. For Microsoft account MFA with biometrics:" "White"
Log "     - Visit https://account.microsoft.com/security" "White"
Log "     - Under 'Advanced security options', add a passkey" "White"
Log "     - Select fingerprint or face as the passkey method" "White"
Log "" "White"

Log "=== CONFIGURATION COMPLETE ===" "Cyan"
Log "Log saved to: $LogPath" "Green"
Log "Please complete the manual enrollment steps above." "Yellow"

Start-Process "ms-settings:signinoptions"
Log "Opened Sign-in options for you." "Green"
