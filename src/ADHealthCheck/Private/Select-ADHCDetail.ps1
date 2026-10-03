function Select-ADHCDetail {
    <#
    .SYNOPSIS
        Caps a list of detail lines and notes how many were left out.
    #>
    [CmdletBinding()]
    [OutputType([string[]], [object[]])]
    param(
        [AllowEmptyCollection()]
        [string[]] $Item = @(),

        [int] $Limit = 50
    )

    $all = @($Item | Sort-Object)
    if ($all.Count -le $Limit) {
        return , $all
    }
    $kept = @($all | Select-Object -First $Limit)
    $kept += "... and $($all.Count - $Limit) more"
    return , $kept
}
