<#
.SYNOPSIS
    Compares two JSON reports and shows which rules got better or worse.
.EXAMPLE
    ./Compare-HealthCheckRun.ps1 -Before .\reports\last-week.json -After .\reports\today.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Before,

    [Parameter(Mandatory)]
    [string] $After
)

$rank = @{ Pass = 0; Skipped = 0; Warning = 1; Error = 1; Fail = 2 }
$old = Get-Content -Path $Before -Raw | ConvertFrom-Json
$new = Get-Content -Path $After -Raw | ConvertFrom-Json
$oldById = @{}
foreach ($result in $old.Results) { $oldById[$result.Id] = $result }

"Score: $($old.Summary.Score) -> $($new.Summary.Score)"
foreach ($result in $new.Results) {
    $previous = $oldById[$result.Id]
    if (-not $previous -or $previous.Status -eq $result.Status) { continue }
    $direction = if ($rank[$result.Status] -gt $rank[$previous.Status]) { 'WORSE ' } else { 'BETTER' }
    [pscustomobject]@{
        Change = $direction
        Id     = $result.Id
        Before = $previous.Status
        After  = $result.Status
        Title  = $result.Title
    }
}
