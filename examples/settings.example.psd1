# Copy, edit, and pass with: Invoke-ADHealthCheck -ConfigurationPath .\settings.psd1
# Only include the keys you want to change. Unknown keys are rejected.
@{
    StaleUserDays           = 60
    StaleComputerDays       = 60
    MaxDomainAdmins         = 3
    KrbtgtMaxPasswordAgeDays = 180
    PrivilegedGroups        = @(
        'Domain Admins'
        'Enterprise Admins'
        'Schema Admins'
        'Administrators'
        'Account Operators'
        'Backup Operators'
        'Server Operators'
        'Print Operators'
        'DnsAdmins'
        'Group Policy Creator Owners'
    )
}
