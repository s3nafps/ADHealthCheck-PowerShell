@{
    Id             = 'ADHC-REP-002'
    Category       = 'Replication'
    Title          = 'Inbound replication is recent'
    Severity       = 'High'
    Description    = 'A partner that has not replicated successfully within the expected window is silently drifting, even when no failure is logged.'
    Recommendation = 'Check site links and schedules, then force replication with repadmin /syncall /AdeP and confirm it succeeds.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/manage/understand-replication-latency')
    Requires       = @('Replication')
    Test           = {
        param($Context)
        $warn = @()
        $fail = @()
        foreach ($link in $Context.Data.Replication.Partners) {
            if ($null -eq $link.LastReplicationSuccess) {
                $fail += "$($link.Server) <- $($link.Partner): never replicated successfully"
                continue
            }
            $hours = ($Context.Now - [datetime]$link.LastReplicationSuccess).TotalHours
            $line = '{0} <- {1}: last success {2:N1} hours ago' -f $link.Server, $link.Partner, $hours
            if ($hours -ge $Context.Settings.ReplicationFailureHours) { $fail += $line }
            elseif ($hours -ge $Context.Settings.ReplicationWarningHours) { $warn += $line }
        }
        if ($fail.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($fail.Count) link(s) have not replicated in $($Context.Settings.ReplicationFailureHours) hours."; Details = $fail + $warn; AffectedCount = $fail.Count }
        }
        if ($warn.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($warn.Count) link(s) have not replicated in $($Context.Settings.ReplicationWarningHours) hours."; Details = $warn }
        }
        $count = @($Context.Data.Replication.Partners).Count
        return @{ Status = 'Pass'; Message = "All $count inbound link(s) replicated within $($Context.Settings.ReplicationWarningHours) hours." }
    }
}
