function Import-ADHCRuleSet {
    <#
    .SYNOPSIS
        Loads and validates every rule definition in a folder.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $required = @('Id', 'Category', 'Title', 'Severity', 'Description', 'Recommendation', 'Requires', 'Test')
    $validSeverity = @('Info', 'Low', 'Medium', 'High', 'Critical')
    $registry = [ordered]@{}

    foreach ($file in (Get-ChildItem -Path $Path -Filter '*.ps1' -File | Sort-Object -Property Name)) {
        $rule = & $file.FullName
        if ($rule -isnot [hashtable]) {
            throw "Rule file '$($file.Name)' must return a hashtable."
        }
        foreach ($key in $required) {
            if (-not $rule.ContainsKey($key)) {
                throw "Rule file '$($file.Name)' is missing the '$key' key."
            }
        }
        if ($validSeverity -notcontains $rule.Severity) {
            throw "Rule '$($rule.Id)' has invalid severity '$($rule.Severity)'."
        }
        if ($rule.Test -isnot [scriptblock]) {
            throw "Rule '$($rule.Id)' Test must be a scriptblock."
        }
        if ($registry.Contains($rule.Id)) {
            throw "Duplicate rule id '$($rule.Id)' in '$($file.Name)'."
        }
        if (-not $rule.ContainsKey('References')) {
            $rule.References = @()
        }
        $registry[$rule.Id] = $rule
    }

    return $registry
}
