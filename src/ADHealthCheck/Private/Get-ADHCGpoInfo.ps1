function Get-ADHCGpoInfo {
    <#
    .SYNOPSIS
        Collects GPOs with their link counts and version numbers.
    .DESCRIPTION
        Links are counted from gPLink on the domain head, every OU and every site,
        which avoids generating a full XML report per GPO.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory)]
        [string] $DomainName,

        [Parameter(Mandatory)]
        [string] $DomainDistinguishedName,

        [hashtable] $Connection = @{}
    )

    $gpoParams = @{ All = $true; Domain = $DomainName; ErrorAction = 'Stop' }
    if ($Connection.ContainsKey('Server')) { $gpoParams.Server = $Connection.Server }
    $gpos = Get-GPO @gpoParams

    $linkCount = @{}
    $linked = @()
    $linked += Get-ADObject -Identity $DomainDistinguishedName -Properties gPLink @Connection -ErrorAction Stop
    $linked += Get-ADOrganizationalUnit -Filter * -Properties gPLink @Connection -ErrorAction Stop
    try {
        $configNC = (Get-ADRootDSE @Connection -ErrorAction Stop).configurationNamingContext
        $linked += Get-ADObject -SearchBase "CN=Sites,$configNC" -LDAPFilter '(objectClass=site)' -Properties gPLink @Connection -ErrorAction Stop
    }
    catch {
        Write-Verbose "Site GPO links could not be read: $($_.Exception.Message)"
    }

    foreach ($container in $linked) {
        if (-not $container.PSObject.Properties['gPLink'] -or -not $container.gPLink) { continue }
        foreach ($match in [regex]::Matches([string]$container.gPLink, 'cn=\{([0-9a-fA-F-]{36})\}', 'IgnoreCase')) {
            $guid = $match.Groups[1].Value.ToLowerInvariant()
            $linkCount[$guid] = 1 + [int]$linkCount[$guid]
        }
    }

    foreach ($gpo in $gpos) {
        $id = ([string]$gpo.Id).ToLowerInvariant()
        [pscustomobject]@{
            DisplayName      = [string]$gpo.DisplayName
            Id               = $id
            GpoStatus        = [string]$gpo.GpoStatus
            UserVersion      = [int]$gpo.User.DSVersion
            ComputerVersion  = [int]$gpo.Computer.DSVersion
            ModificationTime = $gpo.ModificationTime
            LinkCount        = [int]$linkCount[$id]
        }
    }
}
