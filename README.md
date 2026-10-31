# Windows Server Setup

One-command personal setup for **Windows Server 2022 Desktop Experience, build 20348**, using an interactive Administrator session and 64-bit Windows PowerShell 5.1.

Installs Chrome and WinRAR from their vendors, applies the tested Start layout and sharing fixes, and sets the desktop preferences used on Waqaar's Windows VPS machines.

## Install

Open **Windows PowerShell as Administrator** under the Windows account whose desktop you want to configure. Run:

```powershell
$f = Join-Path $env:TEMP 'windows-server-install.ps1'; Invoke-WebRequest 'https://raw.githubusercontent.com/waqaarhussain/windows-server-setup/main/install.ps1' -UseBasicParsing -OutFile $f; powershell.exe -NoProfile -ExecutionPolicy Bypass -File $f
```

The same command fetches the latest version when rerun. It reapplies the settings and reruns the application installers. It does not schedule updates or restart/sign out automatically. Sign out and sign back in afterwards; some preferences can require a reboot.

Execution-policy Bypass applies only to the child PowerShell process. Managed policy can still prevent execution.

## What it configures

| Item | Behaviour |
| --- | --- |
| Chrome | Installs the stable x64 enterprise MSI from Google and checks its Authenticode signature |
| WinRAR | Finds the English stable x64 release on RARLAB, checks its signature, installs silently, optionally applies a local licence |
| IE Enhanced Security | Disables the Administrator and user registry settings |
| Time zone | Sets GMT Standard Time, including UK daylight-saving rules |
| System tray | Writes the legacy Explorer preference to show all icons |
| Scaling | Writes the automatic blurry-app scaling preferences |
| Power plan | Activates High Performance, duplicating the built-in plan if necessary |
| Display and sleep | Sets AC/DC display and standby timeouts to never |
| Start menu | Keeps the app list, disables usage/recent-item preferences and enforces hiding the Recently added section |
| Start tiles | Applies the empty Server 2022 Start layout policy to the current user |
| Taskbar | Includes Chrome in the layout; existing order and removing Edge remain manual |
| Discovery and sharing | Starts the dependency services and enables both entire firewall groups, including outbound rules, for detected active Private/Domain profiles |
| Notifications | Disables the configured toast/app-notification preferences |

The Recently added policy can grey out the Settings toggle. Per-app blue “New” labels are a separate shell behaviour and are not guaranteed to disappear. Layout policy can restrict Start customisation. Tray/scaling preferences and the final UI need checking on each Windows image.

Sharing skips Public profiles. This retains the tested baseline's restriction even if Public is the only active profile; the sharing step then reports failure. With multiple active supported profiles, all detected profiles are configured together. These are settings for the profiles active during setup; there is no watcher for later network changes.

On a VPS, Private does not mean the interface is inaccessible from the internet. Restrict SMB, NetBIOS and discovery traffic using the provider firewall or VPN before using sharing. The script does not configure the provider firewall or create shares.

## WinRAR licence

No licence is embedded or downloaded. Put your own **rarreg.key** on your Desktop before installation, or beside `install.ps1`. The installer detects it and copies it into WinRAR after installation. You can also pass it explicitly:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -WinRARLicensePath 'C:\Private\rarreg.key'
```

Without a supplied file, WinRAR installs normally and an existing installed licence is left alone. A successful copy check establishes byte equality, not licence validity. Licence and certificate files are excluded by `.gitignore`; do not force-add them.

## Download verification

The online installer resolves `main` to one commit, then downloads the manifest and setup files from that exact commit. It checks SHA-256 before executing setup. Application installers must have valid signatures matching the expected vendor.

The initial bootstrap and checksum manifest are trusted from the same GitHub repository. This detects mismatched or corrupted package files; it is not independent protection against a compromised repository. Review the scripts before first use.

## Local package

Extract the ZIP, open Administrator Windows PowerShell in the extracted directory, and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -FromLocalPackage
```

This uses the included setup scripts and checksums. Internet access is still needed for Chrome and WinRAR downloads.

## Results and layout policy removal

Each setup step records its result. Failures do not stop the remaining steps, but the script throws after the final summary if any step failed. Check `C:\ProgramData\WindowsVPSSetup\Logs` for the transcript and CSV results. “Applied” means the step completed; check the Windows UI after signing in again.

To remove the custom Start/taskbar layout policy for the current user:

```powershell
& 'C:\ProgramData\WindowsVPSSetup\Disable-CustomLayout.ps1'
```

Sign out and back in. This removes only `StartLayoutFile` and `LockedStartLayout`; it does not reconstruct old pins or undo other settings. If Explorer policy already exists, the setup retains an initial `.reg` export for manual review. The export is not a full-system backup.

## Validation and maintenance

The consolidated script has not been executed on a Windows VPS as a whole. Individual fixes were tested on the original Server 2022 machine. Repository packaging passed syntax parsing, XML, checksum and private-licence checks; the Windows workflow parses every script, checks the manifest, and parses the embedded layout XML without applying the settings. The workflow runs on pushes and pull requests. A fresh VPS snapshot remains the appropriate integration test.

When setup or the layout-removal script changes, regenerate `manifest.json` with the SHA-256 of the exact tracked file bytes. Keep PowerShell files as UTF-8 without BOM and LF line endings, as configured in `.gitattributes`, so raw downloads and local checkout bytes agree.

Relevant Microsoft references: [Invoke-WebRequest](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-5.1), [Set-NetFirewallRule](https://learn.microsoft.com/en-us/powershell/module/netsecurity/set-netfirewallrule?view=windowsserver2022-ps).
