<#
.SYNOPSIS
    Weekly scheduled health check: writes reports, prunes old ones, and returns a
    non-zero exit code when there are failures so the scheduler or monitoring
    system can alert.
.EXAMPLE
    # Register as a weekly task running under a gMSA (no stored password):
    $action  = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-NoProfile -File C:\Scripts\Invoke-WeeklyHealthCheck.ps1 -OutputPath D:\Reports\AD'
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 6am
    $principal = New-ScheduledTaskPrincipal -UserId 'CONTOSO\gmsa-adaudit$' -LogonType Password
    Register-ScheduledTask -TaskName 'AD Health Check' -Action $action -Trigger $trigger -Principal $principal
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $OutputPath,

    [string] $ConfigurationPath,

    [int] $KeepDays = 90,

    [ValidateSet('Critical', 'High', 'Medium', 'Low')]
    [string] $FailOnSeverity = 'High'
)

$ErrorActionPreference = 'Stop'
Import-Module ADHealthCheck

$params = @{ OutputPath = $OutputPath }
if ($ConfigurationPath) { $params.ConfigurationPath = $ConfigurationPath }
$report = Invoke-ADHealthCheck @params

Get-ChildItem -Path $OutputPath -Filter 'ADHealthCheck_*' -File |
    Where-Object LastWriteTime -lt (Get-Date).AddDays(-$KeepDays) |
    Remove-Item

$order = @('Critical', 'High', 'Medium', 'Low')
$blocking = $order[0..([array]::IndexOf($order, $FailOnSeverity))]
$failures = @($report.Results | Where-Object { $_.Status -eq 'Fail' -and $blocking -contains $_.Severity })

Write-Output ("{0}: score {1} ({2}), {3} failed, {4} warnings. Report: {5}" -f $report.Domain, $report.Summary.Score,
    $report.Summary.Grade, $report.Summary.Fail, $report.Summary.Warning, ($report.ReportFiles -join ', '))

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Warning "$($_.Id) [$($_.Severity)] $($_.Message)" }
    exit 1
}
exit 0
