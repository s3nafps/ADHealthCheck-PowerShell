BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../src/ADHealthCheck/ADHealthCheck.psd1') -Force
    . (Join-Path $PSScriptRoot '../Fixtures/New-TestContext.ps1')
}

Describe 'Invoke-ADHealthCheck with -OutputPath' {
    BeforeAll {
        $context = New-TestContext
        ($context.Data.Users | Where-Object SamAccountName -eq 'alice').SamAccountName = '<script>alert(1)</script>'
        ($context.Data.Users | Where-Object SamAccountName -eq '<script>alert(1)</script>').DoesNotRequirePreAuth = $true
        $report = Invoke-ADHealthCheck -Context $context -OutputPath (Join-Path $TestDrive 'out')
        $html = $report.ReportFiles | Where-Object { $_ -like '*.html' }
        $json = $report.ReportFiles | Where-Object { $_ -like '*.json' }
    }

    It 'writes one HTML and one JSON file' {
        $report.ReportFiles.Count | Should -Be 2
        $html | Should -Exist
        $json | Should -Exist
    }

    It 'writes JSON that round-trips with every result' {
        $data = Get-Content -Path $json -Raw | ConvertFrom-Json
        $data.Domain | Should -Be 'contoso.com'
        @($data.Results).Count | Should -Be @(Get-ADHealthCheckDefinition).Count
        ($data.Results | Where-Object Id -eq 'ADHC-KRB-001').Status | Should -Be 'Fail'
        $data.Summary.Fail | Should -Be 1
    }

    It 'renders every rule in the HTML and encodes untrusted values' {
        $content = Get-Content -Path $html -Raw
        foreach ($definition in Get-ADHealthCheckDefinition) {
            $content | Should -Match ([regex]::Escape($definition.Id))
        }
        $content | Should -Not -Match '<script>alert'
        $content | Should -Match '&lt;script&gt;alert'
    }

    It 'does not load anything from the network' {
        $content = Get-Content -Path $html -Raw
        $content | Should -Not -Match '<link[^>]+href="http'
        $content | Should -Not -Match '<script[^>]+src='
    }
}

Describe 'Export-ADHealthCheckReport' {
    It 'writes only the requested format with a custom base name' {
        $report = Invoke-ADHealthCheck -Context (New-TestContext)
        $files = Export-ADHealthCheckReport -Report $report -Path $TestDrive -Format Json -BaseName 'weekly'
        @($files).Count | Should -Be 1
        $files.Name | Should -Be 'weekly.json'
    }

    It 'supports -WhatIf' {
        $report = Invoke-ADHealthCheck -Context (New-TestContext)
        $files = Export-ADHealthCheckReport -Report $report -Path (Join-Path $TestDrive 'whatif') -BaseName 'none' -WhatIf
        $files | Should -BeNullOrEmpty
        Join-Path $TestDrive 'whatif/none.html' | Should -Not -Exist
    }
}
