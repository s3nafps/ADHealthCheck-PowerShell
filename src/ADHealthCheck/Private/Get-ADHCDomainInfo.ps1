function Get-ADHCDomainInfo {
    <#
    .SYNOPSIS
        Collects domain and forest information.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([hashtable] $Connection = @{})

    $domain = Get-ADDomain @Connection -ErrorAction Stop
    $forest = Get-ADForest @Connection -ErrorAction Stop

    [pscustomobject]@{
        Domain = [pscustomobject]@{
            DNSRoot              = [string]$domain.DNSRoot
            NetBIOSName          = [string]$domain.NetBIOSName
            DistinguishedName    = [string]$domain.DistinguishedName
            DomainSID            = [string]$domain.DomainSID
            DomainMode           = [string]$domain.DomainMode
            PDCEmulator          = [string]$domain.PDCEmulator
            RIDMaster            = [string]$domain.RIDMaster
            InfrastructureMaster = [string]$domain.InfrastructureMaster
        }
        Forest = [pscustomobject]@{
            Name               = [string]$forest.Name
            ForestMode         = [string]$forest.ForestMode
            SchemaMaster       = [string]$forest.SchemaMaster
            DomainNamingMaster = [string]$forest.DomainNamingMaster
            RootDomain         = [string]$forest.RootDomain
        }
    }
}
