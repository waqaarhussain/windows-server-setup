# Changelog

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
