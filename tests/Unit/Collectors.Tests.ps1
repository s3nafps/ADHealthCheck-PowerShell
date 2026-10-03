BeforeAll {
    # The ActiveDirectory and GroupPolicy modules are not available on CI runners.
    # Define empty stand-ins so Pester can mock them.
    foreach ($name in 'Get-ADDomain', 'Get-ADForest', 'Get-ADDomainController', 'Get-ADUser', 'Get-ADComputer',
        'Get-ADGroup', 'Get-ADGroupMember', 'Get-ADReplicationFailure', 'Get-ADReplicationPartnerMetadata',
        'Get-ADDefaultDomainPasswordPolicy', 'Get-ADOptionalFeature', 'Get-GPO', 'Get-ADObject',
        'Get-ADOrganizationalUnit', 'Get-ADRootDSE', 'Resolve-DnsName') {
        if (-not (Get-Command -Name $name -ErrorAction SilentlyContinue)) {
            New-Item -Path "function:global:$name" -Force -Value {
                param($Filter, $Identity, $Properties, $ResultSetSize, $Server, $Credential, $LDAPFilter, $SearchBase,
                    $Target, $Scope, $PartnerType, [switch] $Recursive, [switch] $All, $Domain, $Name, $Type)
            } | Out-Null
        }
    }
    Import-Module (Join-Path $PSScriptRoot '../../src/ADHealthCheck/ADHealthCheck.psd1') -Force
}

Describe 'Get-ADHCUserInfo' {
    It 'normalizes users and decodes the DES-only flag' {
        Mock -ModuleName ADHealthCheck Get-ADUser {
            [pscustomobject]@{
                SamAccountName = 'svc-legacy'; DistinguishedName = 'CN=svc-legacy'; SID = 'S-1-5-21-1-2-3-1200'; Enabled = $true
                LastLogonDate = $null; PasswordLastSet = [datetime]'2020-01-01'; PasswordNeverExpires = $true; PasswordNotRequired = $false
                DoesNotRequirePreAuth = $false; AllowReversiblePasswordEncryption = $false; ServicePrincipalName = @('HTTP/legacy')
                AdminCount = $null; AccountNotDelegated = $false; userAccountControl = 0x210200
            }
        }
        $user = InModuleScope ADHealthCheck { Get-ADHCUserInfo }
        $user.UseDesKeyOnly | Should -BeTrue
        $user.AdminCount | Should -Be 0
        $user.ServicePrincipalName | Should -Be @('HTTP/legacy')
    }
}

Describe 'Get-ADHCComputerInfo' {
    It 'detects Windows LAPS when only its attribute exists in the schema' {
        Mock -ModuleName ADHealthCheck Get-ADComputer {
            if ($Properties -contains 'ms-Mcs-AdmPwdExpirationTime') { throw 'One or more properties are invalid.' }
            if ($ResultSetSize -eq 1) { return [pscustomobject]@{ Name = 'probe' } }
            [pscustomobject]@{ Name = 'WS01'; DistinguishedName = 'CN=WS01'; Enabled = $true; LastLogonDate = (Get-Date); OperatingSystem = 'Windows 11'; TrustedForDelegation = $false; PrimaryGroupID = 515; 'msLAPS-PasswordExpirationTime' = 133000000000000000 }
            [pscustomobject]@{ Name = 'WS02'; DistinguishedName = 'CN=WS02'; Enabled = $true; LastLogonDate = (Get-Date); OperatingSystem = 'Windows 11'; TrustedForDelegation = $false; PrimaryGroupID = 515; 'msLAPS-PasswordExpirationTime' = $null }
            [pscustomobject]@{ Name = 'DC01'; DistinguishedName = 'CN=DC01'; Enabled = $true; LastLogonDate = (Get-Date); OperatingSystem = 'Windows Server 2022'; TrustedForDelegation = $true; PrimaryGroupID = 516; 'msLAPS-PasswordExpirationTime' = $null }
        }
        $info = InModuleScope ADHealthCheck { Get-ADHCComputerInfo }
        $info.LapsSchema | Should -Be 'Windows LAPS'
        ($info.Computers | Where-Object Name -eq 'WS01').HasLaps | Should -BeTrue
        ($info.Computers | Where-Object Name -eq 'WS02').HasLaps | Should -BeFalse
        ($info.Computers | Where-Object Name -eq 'DC01').IsDomainController | Should -BeTrue
    }

    It 'reports None when no LAPS schema exists' {
        Mock -ModuleName ADHealthCheck Get-ADComputer {
            if ($ResultSetSize -eq 1) { throw 'One or more properties are invalid.' }
            [pscustomobject]@{ Name = 'WS01'; DistinguishedName = 'CN=WS01'; Enabled = $true; LastLogonDate = $null; OperatingSystem = ''; TrustedForDelegation = $false; PrimaryGroupID = 515 }
        }
        $info = InModuleScope ADHealthCheck { Get-ADHCComputerInfo }
        $info.LapsSchema | Should -Be 'None'
        $info.Computers[0].HasLaps | Should -BeFalse
    }
}

Describe 'Get-ADHCGpoInfo' {
    It 'counts links from the domain head, OUs and sites' {
        $a = '11111111-1111-1111-1111-111111111111'
        $b = '22222222-2222-2222-2222-222222222222'
        Mock -ModuleName ADHealthCheck Get-GPO {
            [pscustomobject]@{ DisplayName = 'A'; Id = [guid]$a; GpoStatus = 'AllSettingsEnabled'; User = @{ DSVersion = 1 }; Computer = @{ DSVersion = 2 }; ModificationTime = (Get-Date) }
            [pscustomobject]@{ DisplayName = 'B'; Id = [guid]$b; GpoStatus = 'AllSettingsEnabled'; User = @{ DSVersion = 0 }; Computer = @{ DSVersion = 0 }; ModificationTime = (Get-Date) }
        }
        Mock -ModuleName ADHealthCheck Get-ADRootDSE { [pscustomobject]@{ configurationNamingContext = 'CN=Configuration,DC=contoso,DC=com' } }
        Mock -ModuleName ADHealthCheck Get-ADObject {
            if ($LDAPFilter) { return [pscustomobject]@{ gPLink = "[LDAP://cn={$($a.ToUpper())},cn=policies,cn=system,DC=contoso,DC=com;0]" } }
            [pscustomobject]@{ gPLink = "[LDAP://cn={$a},cn=policies,cn=system,DC=contoso,DC=com;0]" }
        }
        Mock -ModuleName ADHealthCheck Get-ADOrganizationalUnit {
            [pscustomobject]@{ gPLink = "[LDAP://cn={$a},cn=policies;0][LDAP://cn={$a},cn=policies;2]" }
            [pscustomobject]@{ gPLink = $null }
        }
        $gpos = InModuleScope ADHealthCheck { Get-ADHCGpoInfo -DomainName 'contoso.com' -DomainDistinguishedName 'DC=contoso,DC=com' }
        ($gpos | Where-Object DisplayName -eq 'A').LinkCount | Should -Be 4
        ($gpos | Where-Object DisplayName -eq 'B').LinkCount | Should -Be 0
    }
}

Describe 'Get-ADHCDnsSrvInfo' {
    It 'matches DC host names against SRV targets case-insensitively' {
        Mock -ModuleName ADHealthCheck Resolve-DnsName {
            [pscustomobject]@{ NameTarget = 'DC01.contoso.com.' }
            [pscustomobject]@{ IPAddress = '10.0.0.10' }
        }
        $map = InModuleScope ADHealthCheck { Get-ADHCDnsSrvInfo -DomainName 'contoso.com' -DomainControllerHostName 'dc01.contoso.com', 'dc02.contoso.com' }
        $map['dc01.contoso.com'] | Should -BeTrue
        $map['dc02.contoso.com'] | Should -BeFalse
    }
}

Describe 'Get-ADHealthCheckContext' {
    BeforeAll {
        Mock -ModuleName ADHealthCheck Get-ADDomain { [pscustomobject]@{ DNSRoot = 'contoso.com'; NetBIOSName = 'CONTOSO'; DistinguishedName = 'DC=contoso,DC=com'; DomainSID = 'S-1-5-21-1'; DomainMode = 'Windows2016Domain'; PDCEmulator = 'dc01.contoso.com'; RIDMaster = 'dc01.contoso.com'; InfrastructureMaster = 'dc01.contoso.com' } }
        Mock -ModuleName ADHealthCheck Get-ADForest { [pscustomobject]@{ Name = 'contoso.com'; ForestMode = 'Windows2016Forest'; SchemaMaster = 'dc01.contoso.com'; DomainNamingMaster = 'dc01.contoso.com'; RootDomain = 'contoso.com' } }
        Mock -ModuleName ADHealthCheck Get-ADDomainController { [pscustomobject]@{ Name = 'DC01'; HostName = 'dc01.contoso.com'; Site = 'HQ'; IPv4Address = '10.0.0.10'; OperatingSystem = 'Windows Server 2022'; IsGlobalCatalog = $true; IsReadOnly = $false; OperationMasterRoles = @() } }
        Mock -ModuleName ADHealthCheck Get-ADUser { throw 'The server has rejected the client credentials.' }
        Mock -ModuleName ADHealthCheck Get-ADComputer { @() }
        Mock -ModuleName ADHealthCheck Get-ADGroup { [pscustomobject]@{ Name = $Identity } }
        Mock -ModuleName ADHealthCheck Get-ADGroupMember { @() }
        Mock -ModuleName ADHealthCheck Get-ADReplicationFailure { @() }
        Mock -ModuleName ADHealthCheck Get-ADReplicationPartnerMetadata { @() }
        Mock -ModuleName ADHealthCheck Get-ADDefaultDomainPasswordPolicy { [pscustomobject]@{ MinPasswordLength = 14; ComplexityEnabled = $true; PasswordHistoryCount = 24; LockoutThreshold = 5; ReversibleEncryptionEnabled = $false; MaxPasswordAge = [timespan]::FromDays(90) } }
        Mock -ModuleName ADHealthCheck Get-ADOptionalFeature { [pscustomobject]@{ EnabledScopes = @('CN=Partitions') } }
        Mock -ModuleName ADHealthCheck Get-GPO { @() }
        Mock -ModuleName ADHealthCheck Get-ADObject { @() }
        Mock -ModuleName ADHealthCheck Get-ADOrganizationalUnit { @() }
        Mock -ModuleName ADHealthCheck Get-ADRootDSE { [pscustomobject]@{ configurationNamingContext = 'CN=Configuration,DC=contoso,DC=com' } }
    }

    It 'records a failed collector without stopping the others' {
        $context = Get-ADHealthCheckContext -SkipNetworkCheck -WarningAction SilentlyContinue
        $context.Errors.Keys | Should -Contain 'Users'
        $context.Errors.Users | Should -Match 'rejected'
        $context.Data.Keys | Should -Contain 'PasswordPolicy'
        $context.Data.RecycleBin | Should -BeTrue
        $context.Skipped.Keys | Should -Contain 'Ports'
    }

    It 'feeds that state through to rule results' {
        $context = Get-ADHealthCheckContext -SkipNetworkCheck -WarningAction SilentlyContinue
        $results = Invoke-ADHealthCheckRule -Context $context
        ($results | Where-Object Id -eq 'ADHC-KRB-001').Status | Should -Be 'Error'
        ($results | Where-Object Id -eq 'ADHC-INF-003').Status | Should -Be 'Skipped'
        ($results | Where-Object Id -eq 'ADHC-POL-001').Status | Should -Be 'Pass'
    }
}
