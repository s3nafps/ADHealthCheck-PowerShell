function Get-ADHealthCheckDefinition {
    <#
    .SYNOPSIS
        Lists the rules ADHealthCheck can evaluate.
    .DESCRIPTION
        Returns the id, category, severity, description, recommendation and data
        requirements of each rule, without running anything against a domain.
    .PARAMETER Id
        One or more rule ids to return. Wildcards are supported.
    .PARAMETER Category
        One or more categories to return.
    .EXAMPLE
        Get-ADHealthCheckDefinition | Format-Table Id, Severity, Title

        Shows every rule.
    .EXAMPLE
        Get-ADHealthCheckDefinition -Category Kerberos

        Shows only the Kerberos rules.
    #>
    [CmdletBinding()]
    [OutputType('ADHealthCheck.Definition')]
    param(
        [SupportsWildcards()]
        [string[]] $Id = '*',

        [string[]] $Category
    )

    foreach ($rule in $script:RuleRegistry.Values) {
        $idMatch = $false
        foreach ($pattern in $Id) {
            if ($rule.Id -like $pattern) { $idMatch = $true }
        }
        if (-not $idMatch) { continue }
        if ($Category -and $Category -notcontains $rule.Category) { continue }

        [pscustomobject]@{
            PSTypeName     = 'ADHealthCheck.Definition'
            Id             = $rule.Id
            Category       = $rule.Category
            Title          = $rule.Title
            Severity       = $rule.Severity
            Description    = $rule.Description
            Recommendation = $rule.Recommendation
            Requires       = @($rule.Requires)
            References     = @($rule.References)
        }
    }
}
