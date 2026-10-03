@{
    RootModule           = 'ADHealthCheck.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '6f0c7b0e-4f3a-4d55-9a3e-2b8f1c9d7a41'
    Author               = 'Mohamed Senator'
    CompanyName          = 'Mohamed Senator'
    Copyright            = '(c) 2026 Mohamed Senator. MIT License.'
    Description          = 'Audits Active Directory health and security: domain controllers, replication, DNS, FSMO roles, stale and privileged accounts, Kerberos exposure, delegation, password policy, GPOs and LAPS coverage. Produces scored HTML and JSON reports.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport    = @(
        'Invoke-ADHealthCheck'
        'Get-ADHealthCheckDefinition'
        'Get-ADHealthCheckContext'
        'Invoke-ADHealthCheckRule'
        'Export-ADHealthCheckReport'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('ActiveDirectory', 'AD', 'HealthCheck', 'Audit', 'Security', 'Windows', 'Report', 'Kerberos', 'GPO', 'LAPS')
            LicenseUri   = 'https://github.com/s3nafps/ADHealthCheck-PowerShell/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/s3nafps/ADHealthCheck-PowerShell'
            ReleaseNotes = 'https://github.com/s3nafps/ADHealthCheck-PowerShell/blob/main/CHANGELOG.md'
        }
    }
}
