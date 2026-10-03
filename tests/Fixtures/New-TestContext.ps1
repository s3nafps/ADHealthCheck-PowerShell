function New-TestContext {
    <#
    .SYNOPSIS
        Builds a context for a small, healthy domain. Tests mutate it to trigger findings.
    #>
    $now = [datetime]'2026-06-01T12:00:00'
    $settingsPath = Join-Path -Path $PSScriptRoot -ChildPath '../../src/ADHealthCheck/Config/Default.psd1'
    $settings = Import-PowerShellDataFile -Path $settingsPath

    $user = {
        param([string] $Name, [string] $Rid, [bool] $Enabled = $true, [int] $LogonDaysAgo = 1, [int] $PasswordDaysAgo = 30)
        [pscustomobject]@{
            SamAccountName                    = $Name
            DistinguishedName                 = "CN=$Name,CN=Users,DC=contoso,DC=com"
            Sid                               = "S-1-5-21-1111111111-2222222222-3333333333-$Rid"
            Enabled                           = $Enabled
            LastLogonDate                     = $now.AddDays(-$LogonDaysAgo)
            PasswordLastSet                   = $now.AddDays(-$PasswordDaysAgo)
            PasswordNeverExpires              = $false
            PasswordNotRequired               = $false
            DoesNotRequirePreAuth             = $false
            AllowReversiblePasswordEncryption = $false
            UseDesKeyOnly                     = $false
            ServicePrincipalName              = @()
            AdminCount                        = 0
            AccountNotDelegated               = $false
        }
    }
    $computer = {
        param([string] $Name, [bool] $IsDc = $false)
        [pscustomobject]@{
            Name                 = $Name
            DistinguishedName    = "CN=$Name,OU=Computers,DC=contoso,DC=com"
            Enabled              = $true
            LastLogonDate        = $now.AddDays(-2)
            OperatingSystem      = if ($IsDc) { 'Windows Server 2022 Datacenter' } else { 'Windows 11 Enterprise' }
            TrustedForDelegation = $IsDc
            IsDomainController   = $IsDc
            HasLaps              = -not $IsDc
        }
    }
    $member = {
        param([string] $Name, [string] $Class = 'user')
        [pscustomobject]@{ SamAccountName = $Name; ObjectClass = $Class; DistinguishedName = "CN=$Name,DC=contoso,DC=com" }
    }

    $administrator = & $user 'Administrator' '500'
    $administrator.AccountNotDelegated = $true
    $administrator.AdminCount = 1
    $krbtgt = & $user 'krbtgt' '502' $false 400 30
    $daUser = & $user 'da.mohamed' '1105'
    $daUser.AdminCount = 1

    $data = @{
        Domain            = [pscustomobject]@{
            DNSRoot = 'contoso.com'; NetBIOSName = 'CONTOSO'; DistinguishedName = 'DC=contoso,DC=com'
            DomainSID = 'S-1-5-21-1111111111-2222222222-3333333333'; DomainMode = 'Windows2016Domain'
            PDCEmulator = 'dc01.contoso.com'; RIDMaster = 'dc01.contoso.com'; InfrastructureMaster = 'dc02.contoso.com'
        }
        Forest            = [pscustomobject]@{
            Name = 'contoso.com'; ForestMode = 'Windows2016Forest'; SchemaMaster = 'dc01.contoso.com'
            DomainNamingMaster = 'dc01.contoso.com'; RootDomain = 'contoso.com'
        }
        DomainControllers = @(
            [pscustomobject]@{ Name = 'DC01'; HostName = 'dc01.contoso.com'; Site = 'HQ'; IPv4Address = '10.0.0.10'; OperatingSystem = 'Windows Server 2022 Datacenter'; IsGlobalCatalog = $true; IsReadOnly = $false; OperationMasterRoles = @('PDCEmulator', 'RIDMaster', 'SchemaMaster', 'DomainNamingMaster') }
            [pscustomobject]@{ Name = 'DC02'; HostName = 'dc02.contoso.com'; Site = 'HQ'; IPv4Address = '10.0.0.11'; OperatingSystem = 'Windows Server 2019 Standard'; IsGlobalCatalog = $true; IsReadOnly = $false; OperationMasterRoles = @('InfrastructureMaster') }
        )
        Users             = @($administrator, $krbtgt, $daUser, (& $user 'alice' '1106'), (& $user 'bob' '1107'))
        Computers         = @((& $computer 'DC01' $true), (& $computer 'DC02' $true), (& $computer 'WS01'), (& $computer 'WS02'), (& $computer 'APP01'))
        LapsSchema        = 'Windows LAPS'
        Groups            = @{
            'Domain Admins'     = @((& $member 'Administrator'), (& $member 'da.mohamed'))
            'Enterprise Admins' = @((& $member 'Administrator'))
            'Schema Admins'     = @()
            'Administrators'    = @((& $member 'Administrator'), (& $member 'da.mohamed'))
            'Account Operators' = @()
            'Backup Operators'  = @()
            'Server Operators'  = @()
            'Print Operators'   = @()
            'Protected Users'   = @((& $member 'da.mohamed'))
        }
        Replication       = [pscustomobject]@{
            Failures = @()
            Partners = @(
                [pscustomobject]@{ Server = 'dc01.contoso.com'; Partner = 'dc02.contoso.com'; Partition = 'DC=contoso,DC=com'; LastReplicationSuccess = $now.AddMinutes(-20); LastReplicationResult = 0; ConsecutiveReplicationFailures = 0 }
                [pscustomobject]@{ Server = 'dc02.contoso.com'; Partner = 'dc01.contoso.com'; Partition = 'DC=contoso,DC=com'; LastReplicationSuccess = $now.AddMinutes(-15); LastReplicationResult = 0; ConsecutiveReplicationFailures = 0 }
            )
        }
        PasswordPolicy    = [pscustomobject]@{ MinPasswordLength = 14; ComplexityEnabled = $true; PasswordHistoryCount = 24; LockoutThreshold = 10; ReversibleEncryptionEnabled = $false; MaxPasswordAgeDays = 365 }
        Gpos              = @(
            [pscustomobject]@{ DisplayName = 'Default Domain Policy'; Id = '31b2f340-016d-11d2-945f-00c04fb984f9'; GpoStatus = 'AllSettingsEnabled'; UserVersion = 0; ComputerVersion = 6; ModificationTime = $now.AddDays(-40); LinkCount = 1 }
            [pscustomobject]@{ DisplayName = 'Workstation Baseline'; Id = '0b3c1f6a-1d2e-4c5b-9a8f-7e6d5c4b3a21'; GpoStatus = 'UserSettingsDisabled'; UserVersion = 0; ComputerVersion = 12; ModificationTime = $now.AddDays(-5); LinkCount = 2 }
        )
        RecycleBin        = $true
        DnsSrv            = @{ 'dc01.contoso.com' = $true; 'dc02.contoso.com' = $true }
        Ports             = @(foreach ($dc in 'dc01.contoso.com', 'dc02.contoso.com') {
                foreach ($port in $settings.DomainControllerPorts) { [pscustomobject]@{ DomainController = $dc; Port = $port; Open = $true } }
            })
    }

    [pscustomobject]@{
        PSTypeName  = 'ADHealthCheck.Context'
        DomainName  = 'contoso.com'
        ForestName  = 'contoso.com'
        Server      = 'dc01.contoso.com'
        CollectedAt = $now.ToUniversalTime()
        Now         = $now
        Settings    = $settings
        Data        = $data
        Errors      = @{}
        Skipped     = @{}
        Timings     = [ordered]@{}
    }
}
