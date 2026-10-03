@{
    Id             = 'ADHC-GPO-002'
    Category       = 'Group Policy'
    Title          = 'Empty or fully disabled Group Policy Objects'
    Severity       = 'Low'
    Description    = 'GPOs with no settings, or with both user and computer sections disabled, still cost processing time at every logon and refresh.'
    Recommendation = 'Remove empty GPOs, or re-enable the section that holds settings if it was disabled by mistake.'
    References     = @('https://learn.microsoft.com/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/jj134176(v=ws.11)')
    Requires       = @('Gpos')
    Test           = {
        param($Context)
        $flagged = @(foreach ($gpo in $Context.Data.Gpos) {
                if ($gpo.GpoStatus -eq 'AllSettingsDisabled') { "$($gpo.DisplayName) (all settings disabled)" }
                elseif ($gpo.UserVersion -eq 0 -and $gpo.ComputerVersion -eq 0) { "$($gpo.DisplayName) (no settings)" }
            })
        if ($flagged.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($flagged.Count) GPO(s) are empty or fully disabled."; Details = $flagged }
        }
        return @{ Status = 'Pass'; Message = 'No empty or fully disabled GPOs were found.' }
    }
}
