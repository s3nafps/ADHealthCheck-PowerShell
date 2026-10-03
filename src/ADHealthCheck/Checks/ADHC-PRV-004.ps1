@{
    Id             = 'ADHC-PRV-004'
    Category       = 'Privileged Access'
    Title          = 'Disabled or inactive accounts in privileged groups'
    Severity       = 'High'
    Description    = 'Leftover privileged memberships on unused accounts are easy to miss and can be re-enabled or abused without anyone noticing.'
    Recommendation = 'Remove disabled and inactive accounts from every privileged group, then review membership on a schedule.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/plan/security-best-practices/reducing-the-active-directory-attack-surface')
    Requires       = @('Users', 'Groups')
    Test           = {
        param($Context)
        $privileged = Get-ADHCPrivilegedMember -Context $Context
        $users = @{}
        foreach ($user in $Context.Data.Users) { $users[$user.SamAccountName] = $user }
        $limit = $Context.Settings.StaleUserDays

        $flagged = @(foreach ($name in $privileged.Keys) {
                $user = $users[$name]
                if (-not $user) { continue }
                $groups = ($privileged[$name] | Select-Object -Unique) -join ', '
                if (-not $user.Enabled) {
                    "$name is disabled ($groups)"
                    continue
                }
                $days = Get-ADHCDaysSince -Date $user.LastLogonDate -Now $Context.Now
                if ($null -ne $days -and $days -ge $limit) {
                    "$name last logged on $days days ago ($groups)"
                }
            })
        if ($flagged.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($flagged.Count) disabled or inactive account(s) hold privileged membership."; Details = $flagged }
        }
        return @{ Status = 'Pass'; Message = 'All privileged group members are enabled and active.' }
    }
}
