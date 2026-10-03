function Get-ADHCDomainControllerInfo {
    <#
    .SYNOPSIS
        Collects every domain controller in the domain.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param([hashtable] $Connection = @{})

    $controllers = Get-ADDomainController -Filter * @Connection -ErrorAction Stop
    foreach ($dc in $controllers) {
        [pscustomobject]@{
            Name                 = [string]$dc.Name
            HostName             = [string]$dc.HostName
            Site                 = [string]$dc.Site
            IPv4Address          = [string]$dc.IPv4Address
            OperatingSystem      = [string]$dc.OperatingSystem
            IsGlobalCatalog      = [bool]$dc.IsGlobalCatalog
            IsReadOnly           = [bool]$dc.IsReadOnly
            OperationMasterRoles = @($dc.OperationMasterRoles | ForEach-Object { [string]$_ })
        }
    }
}
