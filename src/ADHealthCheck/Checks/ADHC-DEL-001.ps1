@{
    Id             = 'ADHC-DEL-001'
    Category       = 'Delegation'
    Title          = 'Unconstrained delegation on non-DC computers'
    Severity       = 'Critical'
    Description    = 'A server trusted for unconstrained delegation caches the TGT of every user that connects to it. Compromising it, combined with coercion techniques, can yield domain controller tickets.'
    Recommendation = 'Replace unconstrained delegation with constrained or resource-based constrained delegation, and add admins to Protected Users.'
    References     = @('https://learn.microsoft.com/windows-server/security/kerberos/kerberos-constrained-delegation-overview')
    Requires       = @('Computers')
    Test           = {
        param($Context)
        $flagged = @($Context.Data.Computers | Where-Object { $_.Enabled -and $_.TrustedForDelegation -and -not $_.IsDomainController } | ForEach-Object { $_.Name })
        if ($flagged.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($flagged.Count) non-DC computer(s) are trusted for unconstrained delegation."; Details = $flagged }
        }
        return @{ Status = 'Pass'; Message = 'Only domain controllers are trusted for unconstrained delegation.' }
    }
}
