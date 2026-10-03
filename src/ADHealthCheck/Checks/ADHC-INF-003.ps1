@{
    Id             = 'ADHC-INF-003'
    Category       = 'Infrastructure'
    Title          = 'Domain controller service ports are reachable'
    Severity       = 'High'
    Description    = 'Checks DNS, Kerberos, RPC, LDAP, LDAPS, SMB and Global Catalog ports on every domain controller from the host running the audit.'
    Recommendation = 'Confirm the DC services are running and that firewalls between clients and DCs allow the AD ports. LDAPS (636) failing usually means no valid DC certificate.'
    References     = @('https://learn.microsoft.com/troubleshoot/windows-server/networking/service-overview-and-network-port-requirements')
    Requires       = @('Ports')
    Test           = {
        param($Context)
        $closed = @($Context.Data.Ports | Where-Object { -not $_.Open } | ForEach-Object { "$($_.DomainController):$($_.Port)" })
        if ($closed.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($closed.Count) domain controller port(s) did not respond."; Details = $closed }
        }
        $dcCount = @($Context.Data.Ports | Select-Object -ExpandProperty DomainController -Unique).Count
        return @{ Status = 'Pass'; Message = "All tested ports responded on $dcCount domain controller(s)." }
    }
}
