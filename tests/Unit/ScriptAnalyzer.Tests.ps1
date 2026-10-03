Describe 'PSScriptAnalyzer' {
    It 'reports no findings for the module' {
        $root = Join-Path $PSScriptRoot '../..'
        $findings = Invoke-ScriptAnalyzer -Path (Join-Path $root 'src') -Recurse -Settings (Join-Path $root 'PSScriptAnalyzerSettings.psd1')
        $findings | ForEach-Object { "$($_.ScriptName):$($_.Line) [$($_.RuleName)] $($_.Message)" } | Should -BeNullOrEmpty
    }
}
