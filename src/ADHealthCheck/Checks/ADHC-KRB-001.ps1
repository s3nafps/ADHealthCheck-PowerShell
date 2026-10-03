@{
    Id             = 'ADHC-KRB-001'
    Category       = 'Kerberos'
    Title          = 'Accounts without Kerberos pre-authentication (AS-REP roasting)'
    Severity       = 'High'
    Description    = 'Accounts with DoesNotRequirePreAuth let anyone request a ticket encrypted with the account key and crack the password offline.'
    Recommendation = 'Clear "Do not require Kerberos preauthentication" on each account. If an application needs it, give that account a long random password.'
    References     = @('https://attack.mitre.org/techniques/T1558/004/')
    Requires       = @('Users')
    Test           = {
        param($Context)
        $flagged = @($Context.Data.Users | Where-Object { $_.Enabled -and $_.DoesNotRequirePreAuth } | ForEach-Object { $_.SamAccountName })
        if ($flagged.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($flagged.Count) enabled account(s) are exposed to AS-REP roasting."; Details = $flagged }
        }
        return @{ Status = 'Pass'; Message = 'All enabled accounts require Kerberos pre-authentication.' }
    }
}
