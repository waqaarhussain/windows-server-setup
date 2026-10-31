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
| Discovery and sharing | Starts the dependency services and enables both entire firewall groups, including outbound rules, for detected active profiles, including Public |
| Notifications | Disables the configured toast/app-notification preferences |
| Chrome defaults | Imports Chrome defaults for new profiles, checks the current HTTP/HTTPS choices, and opens Default apps if an existing user still needs to select Chrome |
| Optional startup services | Disables only the named consumer-service list below, with original states saved |
| Storage cleanup | Enables daily Storage Sense where installed and schedules native Windows update/temp cleanup at 03:30 local time |

The Recently added policy can grey out the Settings toggle. Per-app blue “New” labels are a separate shell behaviour and are not guaranteed to disappear. Layout policy can restrict Start customisation. Tray/scaling preferences and the final UI need checking on each Windows image.

Sharing now enables discovery and file/printer sharing for all detected active profiles, including Public. Inbound rules in those two groups are scoped to LocalSubnet before being enabled. Native outbound scopes are preserved, including multicast discovery targets. Network categories and RDP rules are unchanged. There is no watcher for later profile changes.

On a VPS, Private does not mean the interface is inaccessible from the internet. Restrict SMB, NetBIOS and discovery traffic using the provider firewall or VPN before using sharing. The script does not configure the provider firewall or create shares.

## Chrome, optional services and storage cleanup

Chrome defaults cover `.htm`, `.html`, `http` and `https`. Setup exports the existing association XML, preserves unrelated mappings, changes only the browser mappings and imports it for new user profiles. A domain-joined machine also receives the local default-associations policy unless another such policy already exists. A domain policy can override local settings.

For an existing standalone VPS user, Windows requires the user's browser selection. If the HTTP/HTTPS UserChoice values already identify Chrome, the step reports Applied. Otherwise setup opens **Default apps** and reports **Needs action**: select Google Chrome under Web browser. It does not forge Windows' protected UserChoice hash or claim a policy write changed the current default. Your screenshot already shows Chrome selected; this step is for future installs too.

The optional-service list is **Fax, MapsBroker, RetailDemo, WMPNetworkSvc, XblAuthManager, XblGameSave, XboxNetApiSvc and XboxGipSvc**. Missing services are skipped; services with running dependent services are skipped. These supply fax, offline maps, retail-demo, Windows Media Player library sharing and Xbox features. Disabling them assumes you do not use those optional features on this VPS. Server 2022 may already omit or disable many of them, so no particular speedup is promised. RDP, networking, Defender, Windows Update, storage services, printing and the discovery/SMB services from the original setup are excluded.

Restore saved optional-service startup types, and restart services that were originally running, from Administrator PowerShell:

```powershell
& 'C:\ProgramData\WindowsVPSSetup\Restore-OptionalServices.ps1'
```

Where the native service and task exist, Storage Sense is enabled **daily** for unused temporary files. Downloads, Recycle Bin and cloud-file dehydration are explicitly excluded. If Storage Sense is absent on the image, setup reports **Fallback configured** and uses scheduled Windows Disk Cleanup; it does not claim the Storage Sense switch was enabled.

The separate **WindowsVPSSetup-StorageCleanup** task runs as SYSTEM at **03:30 local time**, or when next available. It uses a dedicated Disk Cleanup profile, selecting only installed handlers for **Windows Update Cleanup, Temporary Files, Temporary Setup Files and Delivery Optimization Files**, and starts Windows' existing component-cleanup task if it is ready. It skips its run when a servicing restart is pending, known servicing processes are running, Windows Update is busy, or update state cannot be read. Windows decides which files are eligible; the task does not wipe all downloaded updates immediately. Storage Sense has its own native cadence.

No cleanup is executed during setup. The privileged worker is installed under a directory writable only by Administrators and SYSTEM, with read/execute access for Users. Cleanup transcripts are in the existing Logs folder. The worker does not manually delete SoftwareDistribution or WinSxS and does not use DISM `/ResetBase`. File cleanup depends on the image's installed Windows handlers; it must be checked on a test VPS.

## WinRAR licence

The main installer now downloads `rarreg.key` automatically from the configured Google Drive direct-download link, validates the registration-file format, and passes the temporary file to setup. After WinRAR installs, setup copies it to `C:\Program Files\WinRAR\rarreg.key` and checks the copied bytes. The temporary download is removed when installation finishes, including on failure. The normal install command above includes this automatically; no manual Desktop download is required.

The Google Drive URL is visible in this public repository. The registration-file bytes are not committed. The Drive file must be accessible without signing in. An HTML sign-in/confirmation page or a truncated registration file causes installation to stop before setup runs. Format checks do not establish that a licence is valid.

A local `rarreg.key` beside the installer or on your Desktop takes priority over the download. You can also pass a local file explicitly:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -WinRARLicensePath 'C:\Private\rarreg.key'
```

Use `-WinRARLicenseUrl 'https://your-direct-download-url'` to override the configured URL. To install without downloading a licence, use:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -SkipWinRARLicenseDownload
```

Skipping the download still allows an automatically detected local licence. Without a supplied file, WinRAR installs normally and an existing installed licence is left alone. Licence and certificate files remain excluded by `.gitignore`; do not force-add them.

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

The consolidated script has not been executed on a Windows VPS as a whole. Individual fixes were tested on the original Server 2022 machine. Repository packaging passed syntax parsing, XML, checksum and private-licence checks; the Windows workflow parses every script, checks the manifest, parses the embedded layout XML, and tests browser XML merging and the service/cleanup scope without applying the settings. The workflow runs on pushes and pull requests. A fresh VPS snapshot remains the appropriate integration test.

When any downloaded script changes, regenerate `manifest.json` with the SHA-256 of the exact tracked file bytes. Keep PowerShell files as UTF-8 without BOM and LF line endings, as configured in `.gitattributes`, so raw downloads and local checkout bytes agree.

Relevant Microsoft references: [Invoke-WebRequest](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-5.1), [Set-NetFirewallRule](https://learn.microsoft.com/en-us/powershell/module/netsecurity/set-netfirewallrule?view=windowsserver2022-ps).

Additional references: [Google Chrome default associations](https://support.google.com/chrome/a/answer/7009292?hl=en), [Storage Sense policies](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-storage), [Windows Server Storage Sense troubleshooting](https://learn.microsoft.com/en-us/troubleshoot/windows-server/backup-and-storage/troubleshoot-windows-server-storage-sense), [component cleanup](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder).

Registry writes open/create keys without replacing them, and update only the requested values. Regression tests preserve existing values and child keys across repeated writes. This prevents further resets; it cannot reconstruct unrelated settings that an earlier toolkit run may already have removed. Failed steps are also printed in full after the results table.
