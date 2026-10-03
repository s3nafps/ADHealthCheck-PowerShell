function Get-ADHCReplicationInfo {
    <#
    .SYNOPSIS
        Collects replication failures and partner metadata for the domain.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string] $DomainName,

        [hashtable] $Connection = @{}
    )

    $credential = @{}
    if ($Connection.ContainsKey('Credential')) { $credential.Credential = $Connection.Credential }

    $failures = Get-ADReplicationFailure -Target $DomainName -Scope Domain @credential -ErrorAction Stop
    $partners = Get-ADReplicationPartnerMetadata -Target $DomainName -Scope Domain -PartnerType Inbound @credential -ErrorAction Stop

    [pscustomobject]@{
        Failures = @(foreach ($failure in $failures) {
                [pscustomobject]@{
                    Server           = [string]$failure.Server
                    Partner          = [string]$failure.Partner
                    FailureCount     = [int]$failure.FailureCount
                    FirstFailureTime = $failure.FirstFailureTime
                    LastError        = [int]$failure.LastError
                }
            })
        Partners = @(foreach ($partner in $partners) {
                [pscustomobject]@{
                    Server                         = [string]$partner.Server
                    Partner                        = [string]$partner.Partner
                    Partition                      = [string]$partner.Partition
                    LastReplicationSuccess         = $partner.LastReplicationSuccess
                    LastReplicationResult          = [int]$partner.LastReplicationResult
                    ConsecutiveReplicationFailures = [int]$partner.ConsecutiveReplicationFailures
                }
            })
    }
}
