function Get-ADHCConnectionParameter {
    <#
    .SYNOPSIS
        Returns a splat with -Server and -Credential when they were supplied.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string] $Server,

        [System.Management.Automation.PSCredential] $Credential
    )

    $splat = @{}
    if ($Server) { $splat.Server = $Server }
    if ($Credential) { $splat.Credential = $Credential }
    return $splat
}
