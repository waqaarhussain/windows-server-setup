# Changelog

## 0.2.3, 2026-11-01

- Remove the blanket LocalSubnet override that fails on Windows logical-endpoint firewall rules.
- Enable both sharing groups for all active profiles, including Public, while preserving existing address/port/endpoint filters.
- Add installer `-SharingOnly` mode for repairs without reinstalling applications or downloading the licence.
- Include the failing rule name in errors, and test logical-endpoint constraints alongside Public and mixed profiles.

## 0.2.2, 2026-10-31

- Fix unsafe registry key creation: open/create existing keys non-destructively and preserve sibling values and child keys on repeated writes.
- Enable discovery and file/printer sharing for all detected active firewall profiles, including Public, with inbound LocalSubnet scope and native outbound scopes preserved.
- Print complete failure messages after the summary table.
- Add Windows regression checks using an isolated test registry key and mocked Public/mixed-network firewall commands.

## 0.2.1, 2026-10-31

- Integrate the configured Google Drive WinRAR licence download into the main installer and document the automatic install flow.
- Prefer local licence files, allow a URL override or download opt-out, and remove downloaded licence bytes with the installer staging directory.
- Reject sign-in/confirmation pages and truncated registration files before executing setup; add synthetic fixture checks without downloading a real licence in CI.

## 0.2.0, 2026-10-31

- Add Chrome defaults for new profiles, preserve unrelated associations, and report when an existing user still needs the Windows default-browser selection.
- Disable a narrow optional consumer-service list and save original startup types for restoration.
- Enable daily Storage Sense where available, excluding Downloads, Recycle Bin and cloud dehydration.
- Schedule Windows-managed cleanup for eligible old update files and temporary files, with pending-servicing checks and a protected SYSTEM worker.
- Add Windows tests for browser XML merging and the allowed service/cleanup scope.

## 0.1.0, 2026-10-31

- Package the consolidated Windows Server 2022 setup baseline.
- Add an online/local installer with commit-consistent downloads and SHA-256 checks.
- Remove the embedded WinRAR licence; accept a local licence file instead.
- Configure the entire discovery and sharing groups for all active supported profiles together, fixing the last-profile-wins bug.
- Keep taskbar ordering and Edge unpinning manual, matching the accepted baseline.
- Add logs, a final failure signal, a layout-policy removal script, documentation and a Windows validation workflow.

Initial GitHub release. Full Windows integration testing is still required.
