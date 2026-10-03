function Get-ADHCDnsSrvInfo {
    <#
    .SYNOPSIS
        Checks that every domain controller is registered in the _ldap._tcp.dc._msdcs SRV record.
    .OUTPUTS
        Hashtable of DC host name to $true/$false.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string] $DomainName,

        [Parameter(Mandatory)]
        [string[]] $DomainControllerHostName,

        [string] $DnsServer
    )

    $query = @{ Name = "_ldap._tcp.dc._msdcs.$DomainName"; Type = 'SRV'; ErrorAction = 'Stop' }
    if ($DnsServer) { $query.Server = $DnsServer }
    $targets = @(Resolve-DnsName @query |
            Where-Object { $_.PSObject.Properties['NameTarget'] } |
            ForEach-Object { ([string]$_.NameTarget).TrimEnd('.').ToLowerInvariant() })

    $result = @{}
    foreach ($hostName in $DomainControllerHostName) {
        $result[$hostName] = $targets -contains $hostName.ToLowerInvariant()
    }
    return $result
}
