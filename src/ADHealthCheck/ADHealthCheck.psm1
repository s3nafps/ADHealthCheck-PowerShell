#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:ModuleRoot = $PSScriptRoot

foreach ($folder in @('Private', 'Public')) {
    $path = Join-Path -Path $PSScriptRoot -ChildPath $folder
    foreach ($file in (Get-ChildItem -Path $path -Filter '*.ps1' -File | Sort-Object -Property Name)) {
        . $file.FullName
    }
}

# Each file in Checks returns one rule definition (a hashtable). Loading them into a
# registry keeps rules declarative: adding a rule means adding a file, nothing else.
$script:RuleRegistry = Import-ADHCRuleSet -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Checks')

Export-ModuleMember -Function @(
    'Invoke-ADHealthCheck'
    'Get-ADHealthCheckDefinition'
    'Get-ADHealthCheckContext'
    'Invoke-ADHealthCheckRule'
    'Export-ADHealthCheckReport'
)
