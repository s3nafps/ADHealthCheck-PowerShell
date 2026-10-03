@{
    Id             = 'ADHC-DNS-001'
    Category       = 'DNS'
    Title          = 'Domain controllers are registered in DNS'
    Severity       = 'High'
    Description    = 'Clients find domain controllers through the _ldap._tcp.dc._msdcs SRV record. A DC missing from it receives no logons and may indicate a broken Netlogon registration.'
    Recommendation = 'On the missing DC, run nltest /dsregdns or restart the Netlogon service, then check that DNS dynamic updates are allowed for the zone.'
    References     = @('https://learn.microsoft.com/troubleshoot/windows-server/networking/verify-srv-dns-records-have-been-created')
    Requires       = @('DnsSrv')
    Test           = {
        param($Context)
        $missing = @($Context.Data.DnsSrv.Keys | Where-Object { -not $Context.Data.DnsSrv[$_] })
        if ($missing.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($missing.Count) domain controller(s) are missing from the DC locator SRV record."; Details = $missing }
        }
        return @{ Status = 'Pass'; Message = "All $($Context.Data.DnsSrv.Count) domain controller(s) are registered in DNS." }
    }
}
