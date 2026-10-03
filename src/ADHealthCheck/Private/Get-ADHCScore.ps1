function Get-ADHCScore {
    <#
    .SYNOPSIS
        Turns rule results into a 0-100 score and a letter grade.
    .DESCRIPTION
        Each failed rule subtracts a weight based on its severity; a warning subtracts
        half of that. Errors and skipped rules do not change the score but are counted
        so a partial run is visible in the summary.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]] $Result
    )

    $weight = @{ Info = 0; Low = 2; Medium = 5; High = 10; Critical = 20 }
    $penalty = 0.0
    foreach ($item in $Result) {
        switch ($item.Status) {
            'Fail' { $penalty += $weight[$item.Severity] }
            'Warning' { $penalty += $weight[$item.Severity] / 2 }
        }
    }

    $score = [int][math]::Max(0, [math]::Round(100 - $penalty))
    $grade = if ($score -ge 90) { 'A' } elseif ($score -ge 80) { 'B' } elseif ($score -ge 70) { 'C' } elseif ($score -ge 60) { 'D' } else { 'F' }

    $counts = [ordered]@{}
    foreach ($status in @('Pass', 'Warning', 'Fail', 'Error', 'Skipped')) {
        $counts[$status] = @($Result | Where-Object { $_.Status -eq $status }).Count
    }

    $failedBySeverity = [ordered]@{}
    foreach ($severity in @('Critical', 'High', 'Medium', 'Low', 'Info')) {
        $failedBySeverity[$severity] = @($Result | Where-Object { $_.Status -eq 'Fail' -and $_.Severity -eq $severity }).Count
    }

    [pscustomobject]@{
        Score            = $score
        Grade            = $grade
        Total            = @($Result).Count
        Pass             = $counts.Pass
        Warning          = $counts.Warning
        Fail             = $counts.Fail
        Error            = $counts.Error
        Skipped          = $counts.Skipped
        FailedBySeverity = [pscustomobject]$failedBySeverity
    }
}
