function Get-ADHCRecycleBinInfo {
    <#
    .SYNOPSIS
        Returns $true when the AD Recycle Bin optional feature is enabled.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([hashtable] $Connection = @{})

    $feature = Get-ADOptionalFeature -Filter "Name -eq 'Recycle Bin Feature'" @Connection -ErrorAction Stop
    return (@($feature.EnabledScopes).Count -gt 0)
}
