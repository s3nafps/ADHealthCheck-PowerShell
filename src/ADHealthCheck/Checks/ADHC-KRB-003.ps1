@{
    Id             = 'ADHC-KRB-003'
    Category       = 'Kerberos'
    Title          = 'krbtgt password age'
    Severity       = 'High'
    Description    = 'The krbtgt key signs every Kerberos ticket. If it has not been rotated, a past compromise can still be used to forge Golden Tickets.'
    Recommendation = 'Reset the krbtgt password twice, waiting for full replication between resets, using Microsoft''s New-KrbtgtKeys.ps1 script.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/manage/ad-forest-recovery-resetting-the-krbtgt-password')
    Requires       = @('Users')
    Test           = {
        param($Context)
        $krbtgt = @($Context.Data.Users | Where-Object { $_.SamAccountName -eq 'krbtgt' }) | Select-Object -First 1
        if (-not $krbtgt) {
            return @{ Status = 'Warning'; Message = 'The krbtgt account was not found in the collected users.' }
        }
        $age = Get-ADHCDaysSince -Date $krbtgt.PasswordLastSet -Now $Context.Now
        $limit = $Context.Settings.KrbtgtMaxPasswordAgeDays
        if ($null -eq $age -or $age -ge $limit) {
            return @{ Status = 'Fail'; Message = "The krbtgt password was last set $age days ago (limit $limit)."; Details = @("krbtgt password age: $age days"); AffectedCount = 1 }
        }
        return @{ Status = 'Pass'; Message = "The krbtgt password was set $age days ago." }
    }
}
