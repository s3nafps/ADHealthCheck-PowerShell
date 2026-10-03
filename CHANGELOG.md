# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-03

### Added
- 27 rules across infrastructure, replication, DNS, accounts, Kerberos,
  privileged access, delegation, password policy, Group Policy and LAPS.
- `Invoke-ADHealthCheck` with a 0-100 score and A-F grade.
- Self-contained HTML report with status filters, and a JSON report for automation.
- Separate collection (`Get-ADHealthCheckContext`) and evaluation
  (`Invoke-ADHealthCheckRule`) so data can be collected once and evaluated offline.
- Threshold overrides through `-Settings` or a `.psd1` file, with unknown keys rejected.
- Pester test suite that runs without Active Directory, PSScriptAnalyzer gate,
  and CI on PowerShell 7 (Linux, Windows) and Windows PowerShell 5.1.
