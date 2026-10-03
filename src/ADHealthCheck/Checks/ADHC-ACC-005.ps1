@{
    Id             = 'ADHC-ACC-005'
    Category       = 'Accounts'
    Title          = 'Reversible encryption or DES-only Kerberos'
    Severity       = 'High'
    Description    = 'Reversible encryption stores a password that can be decrypted to plain text; DES-only accounts use broken Kerberos encryption.'
    Recommendation = 'Clear AllowReversiblePasswordEncryption and "Use only Kerberos DES encryption types", then reset the password so new keys are generated.'
    References     = @('https://learn.microsoft.com/windows/security/threat-protection/security-policy-settings/store-passwords-using-reversible-encryption')
    Requires       = @('Users')
    Test           = {
        param($Context)
        $flagged = @(foreach ($user in $Context.Data.Users) {
                if (-not $user.Enabled) { continue }
                if ($user.AllowReversiblePasswordEncryption) { "$($user.SamAccountName) (reversible encryption)" }
                if ($user.UseDesKeyOnly) { "$($user.SamAccountName) (DES only)" }
            })
        if ($flagged.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($flagged.Count) weak password storage or encryption setting(s) found."; Details = $flagged }
        }
        return @{ Status = 'Pass'; Message = 'No enabled accounts use reversible encryption or DES-only Kerberos.' }
    }
}
