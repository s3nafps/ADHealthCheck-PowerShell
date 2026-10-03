@{
    Id             = 'ADHC-PRV-001'
    Category       = 'Privileged Access'
    Title          = 'Size of Domain Admins and Enterprise Admins'
    Severity       = 'High'
    Description    = 'Every member of these groups can take over the whole domain or forest. Membership should be a handful of named, dedicated admin accounts.'
    Recommendation = 'Remove everyday and service accounts, delegate narrower rights instead, and adopt a tiered admin model.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/plan/security-best-practices/implementing-least-privilege-administrative-models')
    Requires       = @('Groups')
    Test           = {
        param($Context)
        $limits = [ordered]@{
            'Domain Admins'     = $Context.Settings.MaxDomainAdmins
            'Enterprise Admins' = $Context.Settings.MaxEnterpriseAdmins
        }
        $over = @()
        $summary = @()
        foreach ($group in $limits.Keys) {
            if (-not $Context.Data.Groups.ContainsKey($group) -or $null -eq $Context.Data.Groups[$group]) { continue }
            $members = @($Context.Data.Groups[$group])
            $summary += "${group}: $($members.Count) member(s)"
            if ($members.Count -gt $limits[$group]) {
                $over += "${group}: $($members.Count) members (limit $($limits[$group])) - $(($members | ForEach-Object { $_.SamAccountName }) -join ', ')"
            }
        }
        if ($over.Count -gt 0) {
            return @{ Status = 'Fail'; Message = 'Highly privileged groups have more members than allowed.'; Details = $over }
        }
        return @{ Status = 'Pass'; Message = 'Highly privileged group membership is within limits.'; Details = $summary; AffectedCount = 0 }
    }
}
