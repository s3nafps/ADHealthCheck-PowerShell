@{
    Id             = 'ADHC-KRB-002'
    Category       = 'Kerberos'
    Title          = 'User accounts with service principal names (Kerberoasting)'
    Severity       = 'High'
    Description    = 'Any domain user can request a service ticket for an account with an SPN and crack it offline. A privileged account with an SPN is a direct path to Domain Admin.'
    Recommendation = 'Remove SPNs from privileged accounts. Move services to gMSAs, or use 25+ character random passwords and AES-only encryption on remaining service accounts.'
    References     = @('https://attack.mitre.org/techniques/T1558/003/')
    Requires       = @('Users', 'Groups')
    Test           = {
        param($Context)
        $privileged = Get-ADHCPrivilegedMember -Context $Context
        $withSpn = @($Context.Data.Users | Where-Object { $_.Enabled -and $_.SamAccountName -ne 'krbtgt' -and @($_.ServicePrincipalName).Count -gt 0 })
        $critical = @($withSpn | Where-Object { $privileged.ContainsKey($_.SamAccountName) -or $_.AdminCount -eq 1 })
        if ($critical.Count -gt 0) {
            $details = $critical | ForEach-Object { "$($_.SamAccountName) (privileged): $(@($_.ServicePrincipalName)[0])" }
            return @{ Status = 'Fail'; Message = "$($critical.Count) privileged account(s) have an SPN and can be Kerberoasted."; Details = $details }
        }
        if ($withSpn.Count -gt 0) {
            $details = $withSpn | ForEach-Object { "$($_.SamAccountName): $(@($_.ServicePrincipalName)[0])" }
            return @{ Status = 'Warning'; Message = "$($withSpn.Count) user account(s) have an SPN. None are privileged."; Details = $details }
        }
        return @{ Status = 'Pass'; Message = 'No enabled user accounts have service principal names.' }
    }
}
