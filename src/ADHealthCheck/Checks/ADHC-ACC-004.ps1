@{
    Id             = 'ADHC-ACC-004'
    Category       = 'Accounts'
    Title          = 'Accounts that do not require a password'
    Severity       = 'High'
    Description    = 'PASSWD_NOTREQD lets an account have an empty password regardless of the domain policy.'
    Recommendation = 'Clear the flag with Set-ADUser -PasswordNotRequired $false and set a strong password on each account.'
    References     = @('https://learn.microsoft.com/troubleshoot/windows-server/active-directory/useraccountcontrol-manipulate-account-properties')
    Requires       = @('Users')
    Test           = {
        param($Context)
        $flagged = @($Context.Data.Users | Where-Object { $_.Enabled -and $_.PasswordNotRequired } | ForEach-Object { $_.SamAccountName })
        if ($flagged.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($flagged.Count) enabled account(s) are allowed to have no password."; Details = $flagged }
        }
        return @{ Status = 'Pass'; Message = 'No enabled accounts have PasswordNotRequired set.' }
    }
}
