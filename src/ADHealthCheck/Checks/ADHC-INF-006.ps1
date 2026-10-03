@{
    Id             = 'ADHC-INF-006'
    Category       = 'Infrastructure'
    Title          = 'AD Recycle Bin is enabled'
    Severity       = 'Medium'
    Description    = 'Without the Recycle Bin, a deleted user, group or OU can only be recovered with an authoritative restore from backup.'
    Recommendation = 'Enable it with Enable-ADOptionalFeature "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target <forest>. This cannot be undone.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/get-started/adac/active-directory-recycle-bin')
    Requires       = @('RecycleBin')
    Test           = {
        param($Context)
        if ($Context.Data.RecycleBin) {
            return @{ Status = 'Pass'; Message = 'The AD Recycle Bin is enabled.' }
        }
        return @{ Status = 'Fail'; Message = 'The AD Recycle Bin is not enabled.' }
    }
}
