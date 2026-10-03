@{
    Id             = 'ADHC-REP-001'
    Category       = 'Replication'
    Title          = 'No active replication failures'
    Severity       = 'Critical'
    Description    = 'Replication failures leave domain controllers with different passwords, group memberships and policies, and can lead to lingering objects.'
    Recommendation = 'Run repadmin /showrepl and dcdiag /test:replications on the listed servers, fix DNS or connectivity, and check the Directory Service event log.'
    References     = @('https://learn.microsoft.com/troubleshoot/windows-server/active-directory/diagnose-replication-failures')
    Requires       = @('Replication')
    Test           = {
        param($Context)
        $failing = @($Context.Data.Replication.Failures | Where-Object { $_.FailureCount -gt 0 })
        if ($failing.Count -gt 0) {
            $details = $failing | ForEach-Object { "$($_.Server) <- $($_.Partner): $($_.FailureCount) failure(s), last error $($_.LastError)" }
            return @{ Status = 'Fail'; Message = "$($failing.Count) replication link(s) are failing."; Details = $details }
        }
        return @{ Status = 'Pass'; Message = 'No replication failures were reported.' }
    }
}
