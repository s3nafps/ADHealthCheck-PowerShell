function Get-ADHCDaysSince {
    <#
    .SYNOPSIS
        Whole days between a date and the reference time, or $null when the date is empty.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [AllowNull()]
        [object] $Date,

        [Parameter(Mandatory)]
        [datetime] $Now
    )

    if ($null -eq $Date -or $Date -eq [datetime]::MinValue) {
        return $null
    }
    return [int][math]::Floor(($Now - [datetime]$Date).TotalDays)
}
