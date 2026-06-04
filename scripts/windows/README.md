# Windows Security Scripts for Dell Precision 7540

Automated PowerShell scripts for system sensing, security hardening, tool installation, biometric configuration, and network repair. Built for the Dell Precision 7540 (32 GB RAM, 512 GB SSD) running Windows 10 or 11.

## Quick Start

```powershell
# 1. Clone the repository
git clone https://github.com/salvador-Data/awesome-osint.git
cd awesome-osint/scripts/windows

# 2. Open PowerShell as Administrator
# Right-click Start > Windows Terminal (Admin)

# 3. Allow script execution (one-time)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# 4. Run scripts in order
.\01-system-sense.ps1
.\02-harden-windows.ps1
.\03-install-security-tools.ps1
.\04-configure-biometrics.ps1
.\05-network-config.ps1
```

## Scripts

| Script | Purpose | Time |
|--------|---------|------|
| `01-system-sense.ps1` | Detects hardware, OS, network, security status, and open ports. Saves a full report to your Desktop. | ~30 sec |
| `02-harden-windows.ps1` | Maximum security hardening: Defender, ASR rules, firewall, SMB, telemetry, audit policies, remote access lockdown, and password policies. Creates a restore point first. | ~2 min |
| `03-install-security-tools.ps1` | Installs browsers, dev tools, security tools, and utilities via winget (VS Code, Git, Docker, Wireshark, Nmap, KeePassXC, ProtonVPN, and more). | ~10 min |
| `04-configure-biometrics.ps1` | Enables Windows Hello, configures fingerprint and facial recognition as primary MFA, enables anti-spoofing, and opens enrollment settings. | ~30 sec |
| `05-network-config.ps1` | Repairs WiFi hotspot, resets network stack, configures secure DNS (Cloudflare + Google), enables DNS over HTTPS, disables NetBIOS/LLMNR/WPAD. | ~1 min |

## What Gets Hardened (02-harden-windows.ps1)

- **Windows Defender**: Real-time protection, cloud protection, PUA blocking, network protection, controlled folder access, daily scans, behavior monitoring.
- **Attack Surface Reduction**: 15 ASR rules enabled (blocks Office exploits, script abuse, credential theft, USB threats, WMI persistence).
- **Firewall**: All profiles enabled, default deny inbound, logging enabled.
- **Services**: Disables Remote Registry, telemetry, Xbox services, geolocation, WAP push, and more.
- **Remote Access**: Disables Remote Desktop, Remote Assistance, and WinRM.
- **SMB**: Disables SMBv1, requires signing, enables encryption.
- **Privacy**: Blocks telemetry, advertising ID, Cortana, app suggestions, consumer features.
- **PowerShell**: Script block logging, module logging, and transcription enabled.
- **Audit Policies**: Logon, credential validation, account management, file system, privilege use, and policy changes.
- **Account Security**: 5-attempt lockout, 12-character minimum password, 90-day rotation, guest account disabled, Ctrl+Alt+Del required.
- **Autorun**: Disabled for all drive types.

## Reports

Each script saves a timestamped log to your Desktop:
- `SystemReport_YYYYMMDD_HHMMSS.txt`
- `HardeningLog_YYYYMMDD_HHMMSS.txt`
- `ToolInstallLog_YYYYMMDD_HHMMSS.txt`
- `BiometricsLog_YYYYMMDD_HHMMSS.txt`
- `NetworkLog_YYYYMMDD_HHMMSS.txt`

## Requirements

- Windows 10 (21H2+) or Windows 11
- PowerShell 5.1 or later
- Administrator privileges
- Internet connection (for tool installation)
- winget (Windows Package Manager) for script 03

## Recovery

Script 02 creates a System Restore point before making changes. To revert:
1. Open Start and search for "Create a restore point"
2. Click "System Restore"
3. Select "Pre-Hardening Restore Point"
4. Follow the prompts to restore
