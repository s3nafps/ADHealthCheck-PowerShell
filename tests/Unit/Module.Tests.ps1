BeforeDiscovery {
    $moduleRoot = Join-Path $PSScriptRoot '../../src/ADHealthCheck'
    $ruleFiles = Get-ChildItem -Path (Join-Path $moduleRoot 'Checks') -Filter '*.ps1' | ForEach-Object { @{ File = $_ } }
    Import-Module (Join-Path $moduleRoot 'ADHealthCheck.psd1') -Force
    $publicCommands = (Get-Command -Module ADHealthCheck).Name | ForEach-Object { @{ Name = $_ } }
}

BeforeAll {
    $moduleRoot = Join-Path $PSScriptRoot '../../src/ADHealthCheck'
    $manifestPath = Join-Path $moduleRoot 'ADHealthCheck.psd1'
    Import-Module $manifestPath -Force
}

Describe 'Module manifest' {
    It 'is valid' {
        { Test-ModuleManifest -Path $manifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'exports exactly the public functions' {
        $expected = (Get-ChildItem -Path (Join-Path $moduleRoot 'Public') -Filter '*.ps1').BaseName | Sort-Object
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        @($manifest.FunctionsToExport | Sort-Object) | Should -Be @($expected)
        @((Get-Command -Module ADHealthCheck).Name | Sort-Object) | Should -Be @($expected)
    }

    It 'stays compatible with Windows PowerShell 5.1' {
        (Import-PowerShellDataFile -Path $manifestPath).PowerShellVersion | Should -Be '5.1'
    }
}

Describe 'Source files' {
    It 'contain only ASCII so Windows PowerShell 5.1 reads them correctly' {
        $offenders = Get-ChildItem -Path $moduleRoot -Recurse -Include '*.ps1', '*.psm1', '*.psd1' |
            Where-Object { [System.IO.File]::ReadAllBytes($_.FullName) | Where-Object { $_ -gt 127 } | Select-Object -First 1 } |
            ForEach-Object { $_.Name }
        $offenders | Should -BeNullOrEmpty
    }
}

Describe 'Rule file <File.Name>' -ForEach $ruleFiles {
    BeforeAll {
        $rule = & $File.FullName
    }

    It 'is named after its rule id' {
        $File.BaseName | Should -Be $rule.Id
    }

    It 'uses the ADHC-<area>-<number> id format' {
        $rule.Id | Should -Match '^ADHC-[A-Z]{3,4}-\d{3}$'
    }

    It 'has at least one https reference' {
        @($rule.References).Count | Should -BeGreaterThan 0
        $rule.References | ForEach-Object { $_ | Should -Match '^https://' }
    }

    It 'only requires data keys the collector produces' {
        $known = 'Domain', 'Forest', 'DomainControllers', 'Users', 'Computers', 'LapsSchema', 'Groups', 'Replication', 'PasswordPolicy', 'Gpos', 'RecycleBin', 'DnsSrv', 'Ports'
        $rule.Requires | ForEach-Object { $known | Should -Contain $_ }
    }
}

Describe 'Help for <Name>' -ForEach $publicCommands {
    BeforeAll {
        $help = Get-Help -Name $Name -Full
        $command = Get-Command -Name $Name
    }

    It 'has a synopsis and description' {
        $help.Synopsis | Should -Not -BeNullOrEmpty
        $help.Synopsis | Should -Not -Match "^\s*$Name"
        $help.Description.Text | Should -Not -BeNullOrEmpty
    }

    It 'has at least one example' {
        @($help.Examples.Example).Count | Should -BeGreaterThan 0
    }

    It 'documents every parameter' {
        $common = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        foreach ($parameter in $command.Parameters.Keys | Where-Object { $common -notcontains $_ }) {
            $parameterHelp = $help.Parameters.Parameter | Where-Object Name -eq $parameter
            $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty -Because "$Name -$parameter needs help text"
        }
    }
}
