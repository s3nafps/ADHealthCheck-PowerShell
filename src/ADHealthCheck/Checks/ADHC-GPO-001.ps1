@{
    Id             = 'ADHC-GPO-001'
    Category       = 'Group Policy'
    Title          = 'Unlinked Group Policy Objects'
    Severity       = 'Low'
    Description    = 'GPOs that are not linked anywhere apply to nothing. They add noise to troubleshooting and may be linked later with outdated settings.'
    Recommendation = 'Back up and delete GPOs that are no longer needed, or document why they are kept.'
    References     = @('https://learn.microsoft.com/powershell/module/grouppolicy/backup-gpo')
    Requires       = @('Gpos')
    Test           = {
        param($Context)
        $unlinked = @($Context.Data.Gpos | Where-Object { $_.LinkCount -eq 0 } | ForEach-Object { $_.DisplayName })
        if ($unlinked.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($unlinked.Count) GPO(s) are not linked to any site, domain or OU."; Details = $unlinked }
        }
        return @{ Status = 'Pass'; Message = "All $(@($Context.Data.Gpos).Count) GPO(s) are linked." }
    }
}
