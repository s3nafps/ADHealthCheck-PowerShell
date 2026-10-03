@{
    Id             = 'ADHC-ACC-001'
    Category       = 'Accounts'
    Title          = 'Stale enabled user accounts'
    Severity       = 'Medium'
    Description    = 'Enabled accounts that have not logged on for a long time are prime targets for password spraying and are rarely monitored.'
    Recommendation = 'Confirm with the owners, then disable the accounts and move them to a quarantine OU before deletion.'
    References     = @('https://learn.microsoft.com/services-hub/unified/health/remediation-steps-ad/regularly-check-for-and-remove-inactive-user-accounts-in-active-directory')
    Requires       = @('Users')
    Test           = {
        param($Context)
        $limit = $Context.Settings.StaleUserDays
        $stale = foreach ($user in $Context.Data.Users) {
            if (-not $user.Enabled -or $user.SamAccountName -eq 'krbtgt') { continue }
            $days = Get-ADHCDaysSince -Date $user.LastLogonDate -Now $Context.Now
            if ($null -eq $days) {
                $created = Get-ADHCDaysSince -Date $user.PasswordLastSet -Now $Context.Now
                if ($null -eq $created -or $created -ge $limit) { "$($user.SamAccountName) (never logged on)" }
            }
            elseif ($days -ge $limit) {
                "$($user.SamAccountName) (last logon $days days ago)"
            }
        }
        $stale = @($stale)
        if ($stale.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($stale.Count) enabled user account(s) have not logged on in $limit days."; Details = $stale }
        }
        return @{ Status = 'Pass'; Message = "No enabled user accounts are older than $limit days without a logon." }
    }
}
