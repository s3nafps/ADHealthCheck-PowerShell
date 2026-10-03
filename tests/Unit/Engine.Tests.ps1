BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/ADHealthCheck/ADHealthCheck.psd1') -Force
    . (Join-Path $PSScriptRoot '../Fixtures/New-TestContext.ps1')
}

Describe 'Invoke-ADHealthCheckRule' {
    It 'returns Error for rules whose data failed to collect' {
        $context = New-TestContext
        $context.Data.Remove('Replication')
        $context.Errors.Replication = 'RPC server unavailable'
        $results = Invoke-ADHealthCheckRule -Context $context -Category Replication
        $results.Status | Sort-Object -Unique | Should -Be 'Error'
        $results[0].Message | Should -Match 'RPC server unavailable'
    }

    It 'returns Skipped for rules whose data was intentionally not collected' {
        $context = New-TestContext
        $context.Data.Remove('Ports')
        $context.Skipped.Ports = 'Network checks were skipped.'
        $result = Invoke-ADHealthCheckRule -Context $context -Id 'ADHC-INF-003'
        $result.Status | Should -Be 'Skipped'
        $result.Message | Should -Be 'Network checks were skipped.'
    }

    It 'returns Skipped when required data is simply absent' {
        $context = New-TestContext
        $context.Data.Remove('Gpos')
        (Invoke-ADHealthCheckRule -Context $context -Id 'ADHC-GPO-001').Status | Should -Be 'Skipped'
    }

    It 'turns an exception inside a rule into an Error result' {
        $context = New-TestContext
        $context.Data.PasswordPolicy = 'not an object'
        Set-StrictMode -Version Latest
        $result = Invoke-ADHealthCheckRule -Context $context -Id 'ADHC-POL-001'
        $result.Status | Should -Be 'Error'
        $result.Message | Should -Match '^Rule failed'
    }

    It 'filters by id wildcard, category and exclusion' {
        $context = New-TestContext
        @(Invoke-ADHealthCheckRule -Context $context -Id 'ADHC-KRB-*').Count | Should -Be 3
        @(Invoke-ADHealthCheckRule -Context $context -Category 'Group Policy').Count | Should -Be 2
        $ids = (Invoke-ADHealthCheckRule -Context $context -Id 'ADHC-KRB-*' -ExcludeId 'ADHC-KRB-003').Id
        $ids | Should -Not -Contain 'ADHC-KRB-003'
        $ids.Count | Should -Be 2
    }

    It 'caps details at MaxDetailItems' {
        $context = New-TestContext
        $context.Settings.MaxDetailItems = 3
        $context.Data.Users = @($context.Data.Users) + @(1..10 | ForEach-Object {
                $u = $context.Data.Users[3].PSObject.Copy()
                $u.SamAccountName = "user$_"
                $u.PasswordNeverExpires = $true
                $u
            })
        $result = Invoke-ADHealthCheckRule -Context $context -Id 'ADHC-ACC-003'
        $result.AffectedCount | Should -Be 10
        $result.Details.Count | Should -Be 4
        $result.Details[-1] | Should -Be '... and 7 more'
    }
}

Describe 'Scoring' {
    It 'scores a clean run 100 / A' {
        $report = Invoke-ADHealthCheck -Context (New-TestContext)
        $report.Summary.Score | Should -Be 100
        $report.Summary.Grade | Should -Be 'A'
        $report.Summary.Fail | Should -Be 0
    }

    It 'subtracts severity weights for failures and half for warnings' {
        InModuleScope ADHealthCheck {
            $results = @(
                [pscustomobject]@{ Status = 'Fail'; Severity = 'Critical' }
                [pscustomobject]@{ Status = 'Fail'; Severity = 'High' }
                [pscustomobject]@{ Status = 'Warning'; Severity = 'Medium' }
                [pscustomobject]@{ Status = 'Error'; Severity = 'High' }
                [pscustomobject]@{ Status = 'Pass'; Severity = 'High' }
            )
            $summary = Get-ADHCScore -Result $results
            $summary.Score | Should -Be 68
            $summary.Grade | Should -Be 'D'
            $summary.FailedBySeverity.Critical | Should -Be 1
            $summary.Error | Should -Be 1
        }
    }

    It 'never goes below zero' {
        InModuleScope ADHealthCheck {
            $results = 1..10 | ForEach-Object { [pscustomobject]@{ Status = 'Fail'; Severity = 'Critical' } }
            (Get-ADHCScore -Result $results).Score | Should -Be 0
        }
    }
}

Describe 'Settings' {
    It 'merges overrides over defaults' {
        InModuleScope ADHealthCheck {
            $settings = Get-ADHCSetting -Settings @{ StaleUserDays = 30 }
            $settings.StaleUserDays | Should -Be 30
            $settings.StaleComputerDays | Should -Be 90
        }
    }

    It 'reads overrides from a psd1 file, with -Settings winning' {
        $path = Join-Path $TestDrive 'settings.psd1'
        Set-Content -Path $path -Value "@{ StaleUserDays = 45; MaxDomainAdmins = 3 }"
        InModuleScope ADHealthCheck -Parameters @{ Path = $path } {
            param($Path)
            $settings = Get-ADHCSetting -ConfigurationPath $Path -Settings @{ StaleUserDays = 20 }
            $settings.StaleUserDays | Should -Be 20
            $settings.MaxDomainAdmins | Should -Be 3
        }
    }

    It 'rejects unknown keys' {
        InModuleScope ADHealthCheck {
            { Get-ADHCSetting -Settings @{ StaleUserDayz = 30 } } | Should -Throw '*Unknown setting*'
        }
    }
}

Describe 'Helpers' {
    It 'Get-ADHCDaysSince handles null and MinValue' {
        InModuleScope ADHealthCheck {
            $now = [datetime]'2026-06-01'
            Get-ADHCDaysSince -Date $null -Now $now | Should -BeNullOrEmpty
            Get-ADHCDaysSince -Date ([datetime]::MinValue) -Now $now | Should -BeNullOrEmpty
            Get-ADHCDaysSince -Date $now.AddDays(-10) -Now $now | Should -Be 10
        }
    }

    It 'Test-ADHCTcpPort returns false for a closed local port' {
        InModuleScope ADHealthCheck {
            Test-ADHCTcpPort -ComputerName '127.0.0.1' -Port 1 -TimeoutMilliseconds 500 | Should -BeFalse
        }
    }
}
