@{
    Id             = 'ADHC-ACC-002'
    Category       = 'Accounts'
    Title          = 'Stale enabled computer accounts'
    Severity       = 'Low'
    Description    = 'Computer accounts for machines that no longer exist clutter inventory, skew patch and LAPS coverage figures, and can be reused by an attacker.'
    Recommendation = 'Disable computer accounts that have not authenticated within the threshold and delete them after a grace period.'
    References     = @('https://learn.microsoft.com/powershell/module/activedirectory/search-adaccount')
    Requires       = @('Computers')
    Test           = {
        param($Context)
        $limit = $Context.Settings.StaleComputerDays
        $stale = @(foreach ($computer in $Context.Data.Computers) {
                if (-not $computer.Enabled -or $computer.IsDomainController) { continue }
                $days = Get-ADHCDaysSince -Date $computer.LastLogonDate -Now $Context.Now
                if ($null -eq $days) { "$($computer.Name) (never logged on)" }
                elseif ($days -ge $limit) { "$($computer.Name) (last logon $days days ago)" }
            })
        if ($stale.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($stale.Count) enabled computer account(s) have not authenticated in $limit days."; Details = $stale }
        }
        return @{ Status = 'Pass'; Message = "No enabled computer accounts are older than $limit days without a logon." }
    }
}
