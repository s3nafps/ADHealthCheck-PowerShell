BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/ADHealthCheck/ADHealthCheck.psd1') -Force
    . (Join-Path $PSScriptRoot '../Fixtures/New-TestContext.ps1')

    function Invoke-Rule([object] $Context, [string] $Id) {
        Invoke-ADHealthCheckRule -Context $Context -Id $Id
    }
    function Get-User([object] $Context, [string] $Name) {
        $Context.Data.Users | Where-Object SamAccountName -eq $Name
    }
}

Describe 'Healthy baseline' {
    It 'passes every rule against a healthy domain' {
        $results = Invoke-ADHealthCheckRule -Context (New-TestContext)
        $notPassing = $results | Where-Object Status -ne 'Pass' | ForEach-Object { "$($_.Id): $($_.Status) - $($_.Message)" }
        $notPassing | Should -BeNullOrEmpty
        $results.Count | Should -Be @(Get-ADHealthCheckDefinition).Count
    }
}

Describe 'Rule findings' {
    It '<Id> returns <Expected> when <Case>' -ForEach @(
        @{ Id = 'ADHC-INF-001'; Expected = 'Warning'; Case = 'the domain is at 2012 R2'; Mutate = { param($c) $c.Data.Domain.DomainMode = 'Windows2012R2Domain' } }
        @{ Id = 'ADHC-INF-002'; Expected = 'Fail'; Case = 'the PDC role points to a removed DC'; Mutate = { param($c) $c.Data.Domain.PDCEmulator = 'old-dc.contoso.com' } }
        @{ Id = 'ADHC-INF-002'; Expected = 'Pass'; Case = 'forest roles live in another domain'; Mutate = { param($c) $c.Data.Forest.SchemaMaster = 'dc01.root.example' } }
        @{ Id = 'ADHC-INF-003'; Expected = 'Fail'; Case = 'LDAPS is closed on one DC'; Mutate = { param($c) ($c.Data.Ports | Where-Object { $_.Port -eq 636 } | Select-Object -First 1).Open = $false } }
        @{ Id = 'ADHC-INF-004'; Expected = 'Fail'; Case = 'a DC runs Windows Server 2012 R2'; Mutate = { param($c) $c.Data.DomainControllers[1].OperatingSystem = 'Windows Server 2012 R2 Standard' } }
        @{ Id = 'ADHC-INF-004'; Expected = 'Warning'; Case = 'a DC runs Windows Server 2016'; Mutate = { param($c) $c.Data.DomainControllers[1].OperatingSystem = 'Windows Server 2016 Standard' } }
        @{ Id = 'ADHC-INF-005'; Expected = 'Fail'; Case = 'only one DC is a Global Catalog'; Mutate = { param($c) $c.Data.DomainControllers[1].IsGlobalCatalog = $false } }
        @{ Id = 'ADHC-INF-005'; Expected = 'Fail'; Case = 'the second DC is read-only'; Mutate = { param($c) $c.Data.DomainControllers[1].IsReadOnly = $true } }
        @{ Id = 'ADHC-INF-006'; Expected = 'Fail'; Case = 'the Recycle Bin is off'; Mutate = { param($c) $c.Data.RecycleBin = $false } }
        @{ Id = 'ADHC-REP-001'; Expected = 'Fail'; Case = 'a replication link is failing'; Mutate = { param($c) $c.Data.Replication.Failures = @([pscustomobject]@{ Server = 'dc02.contoso.com'; Partner = 'dc01.contoso.com'; FailureCount = 3; FirstFailureTime = $c.Now.AddHours(-5); LastError = 1722 }) } }
        @{ Id = 'ADHC-REP-002'; Expected = 'Warning'; Case = 'a link last replicated 5 hours ago'; Mutate = { param($c) $c.Data.Replication.Partners[0].LastReplicationSuccess = $c.Now.AddHours(-5) } }
        @{ Id = 'ADHC-REP-002'; Expected = 'Fail'; Case = 'a link last replicated 2 days ago'; Mutate = { param($c) $c.Data.Replication.Partners[0].LastReplicationSuccess = $c.Now.AddDays(-2) } }
        @{ Id = 'ADHC-REP-002'; Expected = 'Fail'; Case = 'a link never replicated'; Mutate = { param($c) $c.Data.Replication.Partners[1].LastReplicationSuccess = $null } }
        @{ Id = 'ADHC-DNS-001'; Expected = 'Fail'; Case = 'a DC is missing from the SRV record'; Mutate = { param($c) $c.Data.DnsSrv['dc02.contoso.com'] = $false } }
        @{ Id = 'ADHC-ACC-001'; Expected = 'Warning'; Case = 'a user has not logged on in 200 days'; Mutate = { param($c) (Get-User $c 'bob').LastLogonDate = $c.Now.AddDays(-200) } }
        @{ Id = 'ADHC-ACC-001'; Expected = 'Warning'; Case = 'an old account never logged on'; Mutate = { param($c) $u = Get-User $c 'bob'; $u.LastLogonDate = $null; $u.PasswordLastSet = $c.Now.AddDays(-120) } }
        @{ Id = 'ADHC-ACC-001'; Expected = 'Pass'; Case = 'a new account has not logged on yet'; Mutate = { param($c) $u = Get-User $c 'bob'; $u.LastLogonDate = $null; $u.PasswordLastSet = $c.Now.AddDays(-3) } }
        @{ Id = 'ADHC-ACC-001'; Expected = 'Pass'; Case = 'the stale account is disabled'; Mutate = { param($c) $u = Get-User $c 'bob'; $u.LastLogonDate = $c.Now.AddDays(-400); $u.Enabled = $false } }
        @{ Id = 'ADHC-ACC-002'; Expected = 'Warning'; Case = 'a workstation has not authenticated in 120 days'; Mutate = { param($c) $c.Data.Computers[3].LastLogonDate = $c.Now.AddDays(-120) } }
        @{ Id = 'ADHC-ACC-003'; Expected = 'Warning'; Case = 'a user password never expires'; Mutate = { param($c) (Get-User $c 'alice').PasswordNeverExpires = $true } }
        @{ Id = 'ADHC-ACC-004'; Expected = 'Fail'; Case = 'a user does not require a password'; Mutate = { param($c) (Get-User $c 'alice').PasswordNotRequired = $true } }
        @{ Id = 'ADHC-ACC-005'; Expected = 'Fail'; Case = 'a user allows reversible encryption'; Mutate = { param($c) (Get-User $c 'alice').AllowReversiblePasswordEncryption = $true } }
        @{ Id = 'ADHC-ACC-005'; Expected = 'Fail'; Case = 'a user is DES only'; Mutate = { param($c) (Get-User $c 'alice').UseDesKeyOnly = $true } }
        @{ Id = 'ADHC-ACC-006'; Expected = 'Warning'; Case = 'the built-in Administrator password is 2 years old'; Mutate = { param($c) (Get-User $c 'Administrator').PasswordLastSet = $c.Now.AddDays(-730) } }
        @{ Id = 'ADHC-ACC-006'; Expected = 'Pass'; Case = 'the built-in Administrator is disabled'; Mutate = { param($c) $u = Get-User $c 'Administrator'; $u.Enabled = $false; $u.PasswordLastSet = $c.Now.AddDays(-730) } }
        @{ Id = 'ADHC-KRB-001'; Expected = 'Fail'; Case = 'a user does not require pre-authentication'; Mutate = { param($c) (Get-User $c 'alice').DoesNotRequirePreAuth = $true } }
        @{ Id = 'ADHC-KRB-002'; Expected = 'Warning'; Case = 'a normal user has an SPN'; Mutate = { param($c) (Get-User $c 'bob').ServicePrincipalName = @('MSSQLSvc/sql01.contoso.com:1433') } }
        @{ Id = 'ADHC-KRB-002'; Expected = 'Fail'; Case = 'a Domain Admin has an SPN'; Mutate = { param($c) (Get-User $c 'da.mohamed').ServicePrincipalName = @('HTTP/app01.contoso.com') } }
        @{ Id = 'ADHC-KRB-003'; Expected = 'Fail'; Case = 'krbtgt was last reset 3 years ago'; Mutate = { param($c) (Get-User $c 'krbtgt').PasswordLastSet = $c.Now.AddDays(-1100) } }
        @{ Id = 'ADHC-PRV-001'; Expected = 'Fail'; Case = 'Domain Admins has 7 members'; Mutate = { param($c) $c.Data.Groups['Domain Admins'] = @(1..7 | ForEach-Object { [pscustomobject]@{ SamAccountName = "admin$_"; ObjectClass = 'user'; DistinguishedName = "CN=admin$_" } }) } }
        @{ Id = 'ADHC-PRV-002'; Expected = 'Fail'; Case = 'Schema Admins has a member'; Mutate = { param($c) $c.Data.Groups['Schema Admins'] = @([pscustomobject]@{ SamAccountName = 'Administrator'; ObjectClass = 'user'; DistinguishedName = 'CN=Administrator' }) } }
        @{ Id = 'ADHC-PRV-002'; Expected = 'Pass'; Case = 'Schema Admins does not exist in a child domain'; Mutate = { param($c) $c.Data.Groups['Schema Admins'] = $null } }
        @{ Id = 'ADHC-PRV-003'; Expected = 'Warning'; Case = 'an admin is outside Protected Users'; Mutate = { param($c) $c.Data.Groups['Protected Users'] = @() } }
        @{ Id = 'ADHC-PRV-004'; Expected = 'Fail'; Case = 'a disabled account is a Domain Admin'; Mutate = { param($c) (Get-User $c 'da.mohamed').Enabled = $false } }
        @{ Id = 'ADHC-PRV-004'; Expected = 'Fail'; Case = 'an inactive account is a Domain Admin'; Mutate = { param($c) (Get-User $c 'da.mohamed').LastLogonDate = $c.Now.AddDays(-150) } }
        @{ Id = 'ADHC-DEL-001'; Expected = 'Fail'; Case = 'a member server has unconstrained delegation'; Mutate = { param($c) $c.Data.Computers[4].TrustedForDelegation = $true } }
        @{ Id = 'ADHC-POL-001'; Expected = 'Fail'; Case = 'minimum length is 7'; Mutate = { param($c) $c.Data.PasswordPolicy.MinPasswordLength = 7 } }
        @{ Id = 'ADHC-POL-001'; Expected = 'Warning'; Case = 'minimum length is 10'; Mutate = { param($c) $c.Data.PasswordPolicy.MinPasswordLength = 10 } }
        @{ Id = 'ADHC-POL-001'; Expected = 'Fail'; Case = 'complexity is disabled'; Mutate = { param($c) $c.Data.PasswordPolicy.ComplexityEnabled = $false } }
        @{ Id = 'ADHC-POL-001'; Expected = 'Warning'; Case = 'there is no lockout threshold'; Mutate = { param($c) $c.Data.PasswordPolicy.LockoutThreshold = 0 } }
        @{ Id = 'ADHC-GPO-001'; Expected = 'Warning'; Case = 'a GPO is not linked'; Mutate = { param($c) $c.Data.Gpos[1].LinkCount = 0 } }
        @{ Id = 'ADHC-GPO-002'; Expected = 'Warning'; Case = 'a GPO is empty'; Mutate = { param($c) $c.Data.Gpos[1].ComputerVersion = 0 } }
        @{ Id = 'ADHC-GPO-002'; Expected = 'Warning'; Case = 'a GPO has all settings disabled'; Mutate = { param($c) $c.Data.Gpos[1].GpoStatus = 'AllSettingsDisabled' } }
        @{ Id = 'ADHC-LAPS-001'; Expected = 'Fail'; Case = 'the LAPS schema is missing'; Mutate = { param($c) $c.Data.LapsSchema = 'None' } }
        @{ Id = 'ADHC-LAPS-001'; Expected = 'Warning'; Case = 'one of three computers lacks LAPS'; Mutate = { param($c) $c.Data.Computers[4].HasLaps = $false } }
        @{ Id = 'ADHC-LAPS-001'; Expected = 'Fail'; Case = 'two of three computers lack LAPS'; Mutate = { param($c) $c.Data.Computers[3].HasLaps = $false; $c.Data.Computers[4].HasLaps = $false } }
    ) {
        $context = New-TestContext
        & $Mutate $context
        $result = Invoke-Rule -Context $context -Id $Id
        $result.Status | Should -Be $Expected -Because $result.Message
    }

    It 'lists the affected objects in Details' {
        $context = New-TestContext
        (Get-User $context 'alice').DoesNotRequirePreAuth = $true
        $result = Invoke-Rule -Context $context -Id 'ADHC-KRB-001'
        $result.Details | Should -Contain 'alice'
        $result.AffectedCount | Should -Be 1
    }

    It 'honours threshold overrides from Settings' {
        $context = New-TestContext
        (Get-User $context 'bob').LastLogonDate = $context.Now.AddDays(-40)
        (Invoke-Rule -Context $context -Id 'ADHC-ACC-001').Status | Should -Be 'Pass'
        $context.Settings.StaleUserDays = 30
        (Invoke-Rule -Context $context -Id 'ADHC-ACC-001').Status | Should -Be 'Warning'
    }
}
