# Default thresholds. Override any key with -Settings @{ Key = Value } or -ConfigurationPath.
@{
    # Accounts
    StaleUserDays                 = 90
    StaleComputerDays             = 90
    KrbtgtMaxPasswordAgeDays      = 180
    BuiltinAdminMaxPasswordAgeDays = 365

    # Privileged access
    MaxDomainAdmins               = 5
    MaxEnterpriseAdmins           = 2
    PrivilegedGroups              = @(
        'Domain Admins'
        'Enterprise Admins'
        'Schema Admins'
        'Administrators'
        'Account Operators'
        'Backup Operators'
        'Server Operators'
        'Print Operators'
    )

    # Replication
    ReplicationWarningHours       = 3
    ReplicationFailureHours       = 24

    # Password policy
    MinimumPasswordLength         = 14
    MinimumPasswordLengthCritical = 8
    MinimumPasswordHistory        = 24

    # LAPS coverage of enabled, non-DC computers (percent)
    LapsCoverageWarningPercent    = 95
    LapsCoverageFailurePercent    = 50

    # Functional level: anything below this is reported
    MinimumFunctionalLevel        = 'Windows2016'

    # Network checks
    DomainControllerPorts         = @(53, 88, 135, 389, 445, 636, 3268)
    PortTimeoutMilliseconds       = 1500

    # Maximum objects listed in a finding's details
    MaxDetailItems                = 50
}
