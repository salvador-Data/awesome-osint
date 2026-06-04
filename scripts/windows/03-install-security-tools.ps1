#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Security Tools Installer for OSINT and Cybersecurity Workstation
.DESCRIPTION
    Installs essential security, OSINT, and development tools via
    winget (Windows Package Manager). Designed for Dell Precision 7540.
.NOTES
    Run as Administrator. Requires winget (pre-installed on Windows 11,
    available via App Installer on Windows 10).
#>

$ErrorActionPreference = "SilentlyContinue"
$LogPath = "$env:USERPROFILE\Desktop\ToolInstallLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Log {
    param([string]$Message, [string]$Color = "White")
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    Add-Content -Path $LogPath -Value $line
}

function Install-Tool {
    param([string]$Id, [string]$Name)
    Log "Installing $Name..." "Yellow"
    $result = winget install --id $Id --accept-source-agreements --accept-package-agreements --silent 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log "  Installed: $Name" "Green"
    } else {
        Log "  Skipped: $Name (already installed or unavailable)" "DarkYellow"
    }
}

Set-Content -Path $LogPath -Value "TOOL INSTALLATION LOG`nStarted: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# Check winget
$wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetCheck) {
    Log "winget not found. Please install App Installer from the Microsoft Store." "Red"
    exit 1
}

Log "=== BROWSERS ===" "Cyan"
Install-Tool "Mozilla.Firefox"            "Firefox (privacy-focused browser)"
Install-Tool "ArcBrowser.Arc"             "Arc Browser"
Install-Tool "ArnoldVRithmo.Tor"          "Tor Browser"

Log "`n=== DEVELOPMENT TOOLS ===" "Cyan"
Install-Tool "Microsoft.VisualStudioCode" "Visual Studio Code"
Install-Tool "Git.Git"                    "Git"
Install-Tool "GitHub.cli"                 "GitHub CLI"
Install-Tool "OpenJS.NodeJS.LTS"         "Node.js LTS"
Install-Tool "Python.Python.3.12"        "Python 3.12"
Install-Tool "Docker.DockerDesktop"       "Docker Desktop"
Install-Tool "Microsoft.WindowsTerminal"  "Windows Terminal"
Install-Tool "JanDeDobbeleer.OhMyPosh"   "Oh My Posh (terminal theme)"

Log "`n=== SECURITY AND OSINT TOOLS ===" "Cyan"
Install-Tool "WiresharkFoundation.Wireshark" "Wireshark"
Install-Tool "Insecure.Nmap"                 "Nmap"
Install-Tool "PuTTY.PuTTY"                  "PuTTY"
Install-Tool "WinSCP.WinSCP"                "WinSCP"
Install-Tool "KeePassXCTeam.KeePassXC"      "KeePassXC (password manager)"
Install-Tool "Bitwarden.Bitwarden"           "Bitwarden (password manager)"
Install-Tool "ProtonTechnologies.ProtonVPN"  "ProtonVPN"
Install-Tool "Cryptomator.Cryptomator"       "Cryptomator (file encryption)"
Install-Tool "VeraCrypt.VeraCrypt"           "VeraCrypt (disk encryption)"

Log "`n=== COMMUNICATION ===" "Cyan"
Install-Tool "Discord.Discord"              "Discord"
Install-Tool "SlackTechnologies.Slack"      "Slack"
Install-Tool "Signal.Signal"                "Signal (encrypted messaging)"

Log "`n=== UTILITIES ===" "Cyan"
Install-Tool "7zip.7zip"                    "7-Zip"
Install-Tool "voidtools.Everything"          "Everything (file search)"
Install-Tool "Notepad++.Notepad++"          "Notepad++"
Install-Tool "SumatraPDF.SumatraPDF"       "SumatraPDF"
Install-Tool "OBSProject.OBSStudio"         "OBS Studio (screen recording)"
Install-Tool "ShareX.ShareX"                "ShareX (screenshot tool)"
Install-Tool "Greenshot.Greenshot"           "Greenshot (screenshot tool)"

Log "`n=== INSTALLATION COMPLETE ===" "Cyan"
Log "Install log saved to: $LogPath" "Green"
Log "Some tools may require a restart to complete setup." "Yellow"

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Log "`nVerifying key installations:" "Cyan"
$checks = @(
    @{ Cmd = "git --version";    Name = "Git" },
    @{ Cmd = "node --version";   Name = "Node.js" },
    @{ Cmd = "python --version"; Name = "Python" },
    @{ Cmd = "gh --version";     Name = "GitHub CLI" },
    @{ Cmd = "nmap --version";   Name = "Nmap" }
)

foreach ($check in $checks) {
    $result = Invoke-Expression $check.Cmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log "  $($check.Name): $($result | Select-Object -First 1)" "Green"
    } else {
        Log "  $($check.Name): Not found (restart may be required)" "Yellow"
    }
}
