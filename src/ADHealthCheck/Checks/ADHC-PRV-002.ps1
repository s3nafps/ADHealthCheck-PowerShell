@{
    Id             = 'ADHC-PRV-002'
    Category       = 'Privileged Access'
    Title          = 'Schema Admins is empty'
    Severity       = 'Medium'
    Description    = 'Schema changes are rare. Standing membership in Schema Admins adds risk with no day-to-day benefit.'
    Recommendation = 'Remove all members and add an account only for the duration of a planned schema change.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/plan/security-best-practices/appendix-g--securing-schema-admins-groups-in-active-directory')
    Requires       = @('Groups')
    Test           = {
        param($Context)
        if (-not $Context.Data.Groups.ContainsKey('Schema Admins') -or $null -eq $Context.Data.Groups['Schema Admins']) {
            return @{ Status = 'Pass'; Message = 'Schema Admins does not exist in this domain (it lives in the forest root).' }
        }
        $members = @($Context.Data.Groups['Schema Admins'] | ForEach-Object { $_.SamAccountName })
        if ($members.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "Schema Admins has $($members.Count) standing member(s)."; Details = $members }
        }
        return @{ Status = 'Pass'; Message = 'Schema Admins is empty.' }
    }
}
