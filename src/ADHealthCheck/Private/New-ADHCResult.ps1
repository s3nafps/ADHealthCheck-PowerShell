function New-ADHCResult {
    <#
    .SYNOPSIS
        Builds a normalized result object for one rule evaluation.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Creates an in-memory object only.')]
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [hashtable] $Rule,

        [Parameter(Mandatory)]
        [ValidateSet('Pass', 'Warning', 'Fail', 'Error', 'Skipped')]
        [string] $Status,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Message,

        [string[]] $Details = @(),

        [int] $AffectedCount = 0,

        [timespan] $Duration = [timespan]::Zero
    )

    [pscustomobject]@{
        PSTypeName     = 'ADHealthCheck.Result'
        Id             = $Rule.Id
        Category       = $Rule.Category
        Title          = $Rule.Title
        Severity       = $Rule.Severity
        Status         = $Status
        Message        = $Message
        AffectedCount  = $AffectedCount
        Details        = @($Details)
        Recommendation = $Rule.Recommendation
        References     = @($Rule.References)
        DurationMs     = [math]::Round($Duration.TotalMilliseconds, 1)
    }
}
