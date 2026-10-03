@{
    Id             = 'ADHC-PRV-003'
    Category       = 'Privileged Access'
    Title          = 'Privileged accounts are protected from delegation'
    Severity       = 'Medium'
    Description    = 'Privileged credentials can be impersonated through Kerberos delegation unless the account is marked sensitive or is in Protected Users.'
    Recommendation = 'Add admin accounts to Protected Users, or set "Account is sensitive and cannot be delegated". Test service accounts first: Protected Users blocks NTLM and delegation.'
    References     = @('https://learn.microsoft.com/windows-server/security/credentials-protection-and-management/protected-users-security-group')
    Requires       = @('Users', 'Groups')
    Test           = {
        param($Context)
        $privileged = Get-ADHCPrivilegedMember -Context $Context
        $protected = @()
        if ($Context.Data.Groups.ContainsKey('Protected Users') -and $null -ne $Context.Data.Groups['Protected Users']) {
            $protected = @($Context.Data.Groups['Protected Users'] | ForEach-Object { $_.SamAccountName })
        }
        $users = @{}
        foreach ($user in $Context.Data.Users) { $users[$user.SamAccountName] = $user }

        $exposed = @(foreach ($name in $privileged.Keys) {
                $user = $users[$name]
                if (-not $user -or -not $user.Enabled) { continue }
                if ($user.AccountNotDelegated -or $protected -contains $name) { continue }
                "$name ($(($privileged[$name] | Select-Object -Unique) -join ', '))"
            })
        if ($exposed.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($exposed.Count) privileged account(s) can be delegated."; Details = $exposed }
        }
        return @{ Status = 'Pass'; Message = 'All enabled privileged accounts are protected from delegation.' }
    }
}
