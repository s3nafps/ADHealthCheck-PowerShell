function Invoke-ADHealthCheckRule {
    <#
    .SYNOPSIS
        Evaluates rules against a collected context.
    .DESCRIPTION
        Rules whose data could not be collected return Error; rules whose data was
        intentionally not collected return Skipped. A rule that throws returns Error
        with the exception message, so one broken rule never stops the run.
    .PARAMETER Context
        The object returned by Get-ADHealthCheckContext.
    .PARAMETER Id
        Rule ids to run. Wildcards are supported. Defaults to all rules.
    .PARAMETER Category
        Only run rules in these categories.
    .PARAMETER ExcludeId
        Rule ids to leave out. Wildcards are supported.
    .EXAMPLE
        Invoke-ADHealthCheckRule -Context $context -Id 'ADHC-KRB-*'
    #>
    [CmdletBinding()]
    [OutputType('ADHealthCheck.Result')]
    param(
        [Parameter(Mandatory)]
        [object] $Context,

        [SupportsWildcards()]
        [string[]] $Id = '*',

        [string[]] $Category,

        [SupportsWildcards()]
        [string[]] $ExcludeId
    )

    $definitions = @(Get-ADHealthCheckDefinition -Id $Id -Category $Category)
    foreach ($definition in $definitions) {
        $excluded = $false
        foreach ($pattern in $ExcludeId) {
            if ($definition.Id -like $pattern) { $excluded = $true }
        }
        if ($excluded) { continue }

        $rule = $script:RuleRegistry[$definition.Id]
        $missing = @($rule.Requires | Where-Object { $Context.Errors.ContainsKey($_) })
        $skippedData = @($rule.Requires | Where-Object { $Context.Skipped.ContainsKey($_) })
        $absent = @($rule.Requires | Where-Object { -not $Context.Data.ContainsKey($_) -and -not $Context.Errors.ContainsKey($_) -and -not $Context.Skipped.ContainsKey($_) })

        if ($missing.Count -gt 0) {
            $reason = ($missing | ForEach-Object { "${_}: $($Context.Errors[$_])" }) -join '; '
            New-ADHCResult -Rule $rule -Status Error -Message "Required data could not be collected. $reason"
            continue
        }
        if ($skippedData.Count -gt 0) {
            $reason = ($skippedData | ForEach-Object { $Context.Skipped[$_] } | Select-Object -Unique) -join ' '
            New-ADHCResult -Rule $rule -Status Skipped -Message $reason
            continue
        }
        if ($absent.Count -gt 0) {
            New-ADHCResult -Rule $rule -Status Skipped -Message "Required data was not collected: $($absent -join ', ')."
            continue
        }

        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $outcome = & $rule.Test $Context
            if ($outcome -isnot [hashtable] -or @('Pass', 'Warning', 'Fail') -notcontains $outcome.Status) {
                throw "Rule returned an invalid outcome; expected a hashtable with Status Pass, Warning or Fail."
            }
            $details = @()
            if ($outcome.ContainsKey('Details')) { $details = @($outcome.Details) }
            $affected = if ($outcome.ContainsKey('AffectedCount')) { [int]$outcome.AffectedCount } else { $details.Count }
            New-ADHCResult -Rule $rule -Status $outcome.Status -Message $outcome.Message `
                -Details (Select-ADHCDetail -Item $details -Limit $Context.Settings.MaxDetailItems) `
                -AffectedCount $affected -Duration $watch.Elapsed
        }
        catch {
            New-ADHCResult -Rule $rule -Status Error -Message "Rule failed: $($_.Exception.Message)" -Duration $watch.Elapsed
        }
    }
}
