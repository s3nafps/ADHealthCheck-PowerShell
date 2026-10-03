@{
    Id             = 'ADHC-ACC-006'
    Category       = 'Accounts'
    Title          = 'Built-in Administrator account'
    Severity       = 'Medium'
    Description    = 'The built-in Administrator (RID 500) cannot be locked out. An enabled account with an old password is a high-value target.'
    Recommendation = 'Use named admin accounts for daily work, rotate the built-in Administrator password and keep it in a vault, or disable it if your recovery process allows.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/plan/security-best-practices/appendix-d--securing-built-in-administrator-accounts-in-active-directory')
    Requires       = @('Users')
    Test           = {
        param($Context)
        $admin = @($Context.Data.Users | Where-Object { $_.Sid -match '-500$' }) | Select-Object -First 1
        if (-not $admin) {
            return @{ Status = 'Warning'; Message = 'The built-in Administrator account was not found in the collected users.' }
        }
        if (-not $admin.Enabled) {
            return @{ Status = 'Pass'; Message = "The built-in Administrator account ($($admin.SamAccountName)) is disabled." }
        }
        $age = Get-ADHCDaysSince -Date $admin.PasswordLastSet -Now $Context.Now
        $limit = $Context.Settings.BuiltinAdminMaxPasswordAgeDays
        $logon = Get-ADHCDaysSince -Date $admin.LastLogonDate -Now $Context.Now
        $details = @("Account: $($admin.SamAccountName)", "Password age: $age days", "Last logon: $(if ($null -eq $logon) { 'never' } else { "$logon days ago" })")
        if ($null -eq $age -or $age -ge $limit) {
            return @{ Status = 'Warning'; Message = "The built-in Administrator is enabled and its password is older than $limit days."; Details = $details; AffectedCount = 1 }
        }
        return @{ Status = 'Pass'; Message = "The built-in Administrator is enabled with a password set $age days ago."; Details = $details; AffectedCount = 0 }
    }
}
