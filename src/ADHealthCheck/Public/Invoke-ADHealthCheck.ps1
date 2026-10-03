function Invoke-ADHealthCheck {
    <#
    .SYNOPSIS
        Audits an Active Directory domain and returns a scored report.
    .DESCRIPTION
        Collects domain data, evaluates every selected rule, scores the results and,
        when -OutputPath is given, writes HTML and/or JSON reports. The returned
        report object can be piped to Export-ADHealthCheckReport or inspected
        directly, for example $report.Results | Where-Object Status -eq 'Fail'.
    .PARAMETER Server
        Domain controller or domain to query.
    .PARAMETER Credential
        Credential used for the AD queries.
    .PARAMETER Context
        A context from Get-ADHealthCheckContext, to evaluate previously collected data.
    .PARAMETER Id
        Rule ids to run. Wildcards are supported.
    .PARAMETER Category
        Only run rules in these categories.
    .PARAMETER ExcludeId
        Rule ids to leave out. Wildcards are supported.
    .PARAMETER Settings
        Hashtable of threshold overrides.
    .PARAMETER ConfigurationPath
        Path to a .psd1 file with threshold overrides.
    .PARAMETER SkipNetworkCheck
        Skips DNS SRV and TCP port checks.
    .PARAMETER OutputPath
        Folder to write report files to.
    .PARAMETER Format
        Report formats to write when -OutputPath is used. Defaults to Html and Json.
    .EXAMPLE
        Invoke-ADHealthCheck -OutputPath C:\Reports

        Audits the current domain and writes HTML and JSON reports.
    .EXAMPLE
        $report = Invoke-ADHealthCheck -Server dc01.contoso.com -Category Kerberos, 'Privileged Access'
        $report.Results | Where-Object Status -ne 'Pass' | Format-Table Id, Status, Message

        Runs two categories and lists everything that needs attention.
    .EXAMPLE
        Invoke-ADHealthCheck -Settings @{ StaleUserDays = 60; MaxDomainAdmins = 3 } -SkipNetworkCheck

        Uses stricter thresholds and skips network probes.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Collect')]
    [OutputType('ADHealthCheck.Report')]
    param(
        [Parameter(ParameterSetName = 'Collect')]
        [string] $Server,

        [Parameter(ParameterSetName = 'Collect')]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter(Mandatory, ParameterSetName = 'Context')]
        [object] $Context,

        [SupportsWildcards()]
        [string[]] $Id = '*',

        [string[]] $Category,

        [SupportsWildcards()]
        [string[]] $ExcludeId,

        [Parameter(ParameterSetName = 'Collect')]
        [hashtable] $Settings,

        [Parameter(ParameterSetName = 'Collect')]
        [string] $ConfigurationPath,

        [Parameter(ParameterSetName = 'Collect')]
        [switch] $SkipNetworkCheck,

        [string] $OutputPath,

        [ValidateSet('Html', 'Json')]
        [string[]] $Format = @('Html', 'Json')
    )

    $started = Get-Date
    if ($PSCmdlet.ParameterSetName -eq 'Collect') {
        $Context = Get-ADHealthCheckContext -Server $Server -Credential $Credential -Settings $Settings `
            -ConfigurationPath $ConfigurationPath -SkipNetworkCheck:$SkipNetworkCheck
    }

    $results = @(Invoke-ADHealthCheckRule -Context $Context -Id $Id -Category $Category -ExcludeId $ExcludeId)
    $summary = Get-ADHCScore -Result $results
    $module = $MyInvocation.MyCommand.Module

    $report = [pscustomobject]@{
        PSTypeName         = 'ADHealthCheck.Report'
        Tool               = 'ADHealthCheck'
        ToolVersion        = if ($module) { [string]$module.Version } else { 'dev' }
        Domain             = $Context.DomainName
        Forest             = $Context.ForestName
        Server             = $Context.Server
        GeneratedAt        = (Get-Date).ToUniversalTime().ToString('o')
        DurationSeconds    = [math]::Round(((Get-Date) - $started).TotalSeconds, 1)
        Summary            = $summary
        Results            = $results
        CollectionErrors   = $Context.Errors
        SkippedCollections = $Context.Skipped
        CollectionTimings  = $Context.Timings
        ReportFiles        = @()
    }

    if ($OutputPath) {
        $report.ReportFiles = @(Export-ADHealthCheckReport -Report $report -Path $OutputPath -Format $Format | ForEach-Object { $_.FullName })
    }

    return $report
}
