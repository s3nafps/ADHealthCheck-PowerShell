@{
    Id             = 'ADHC-ACC-003'
    Category       = 'Accounts'
    Title          = 'Passwords that never expire'
    Severity       = 'Medium'
    Description    = 'Enabled accounts with PasswordNeverExpires keep the same password indefinitely, often for years, and are commonly service accounts with broad rights.'
    Recommendation = 'Move service accounts to group Managed Service Accounts (gMSA). For people, remove the flag or enforce a long passphrase with a fine-grained password policy.'
    References     = @('https://learn.microsoft.com/windows-server/security/group-managed-service-accounts/group-managed-service-accounts-overview')
    Requires       = @('Users')
    Test           = {
        param($Context)
        $flagged = @($Context.Data.Users | Where-Object { $_.Enabled -and $_.PasswordNeverExpires } | ForEach-Object { $_.SamAccountName })
        if ($flagged.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($flagged.Count) enabled account(s) have passwords that never expire."; Details = $flagged }
        }
        return @{ Status = 'Pass'; Message = 'No enabled accounts have PasswordNeverExpires set.' }
    }
}
