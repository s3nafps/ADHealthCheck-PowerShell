@{
    Id             = 'ADHC-POL-001'
    Category       = 'Policy'
    Title          = 'Default domain password and lockout policy'
    Severity       = 'High'
    Description    = 'The default domain policy sets the baseline for every account that is not covered by a fine-grained policy.'
    Recommendation = 'Require at least 14 characters, keep complexity on, remember 24 passwords, never allow reversible encryption, and set an account lockout threshold.'
    References     = @('https://learn.microsoft.com/windows/security/threat-protection/security-policy-settings/password-policy')
    Requires       = @('PasswordPolicy')
    Test           = {
        param($Context)
        $policy = $Context.Data.PasswordPolicy
        $settings = $Context.Settings
        $fail = @()
        $warn = @()
        if ($policy.MinPasswordLength -lt $settings.MinimumPasswordLengthCritical) { $fail += "Minimum length is $($policy.MinPasswordLength) (below $($settings.MinimumPasswordLengthCritical))" }
        elseif ($policy.MinPasswordLength -lt $settings.MinimumPasswordLength) { $warn += "Minimum length is $($policy.MinPasswordLength) (recommended $($settings.MinimumPasswordLength))" }
        if (-not $policy.ComplexityEnabled) { $fail += 'Password complexity is disabled' }
        if ($policy.ReversibleEncryptionEnabled) { $fail += 'Reversible encryption is enabled for all users' }
        if ($policy.LockoutThreshold -eq 0) { $warn += 'No account lockout threshold is set' }
        if ($policy.PasswordHistoryCount -lt $settings.MinimumPasswordHistory) { $warn += "Password history is $($policy.PasswordHistoryCount) (recommended $($settings.MinimumPasswordHistory))" }

        if ($fail.Count -gt 0) {
            return @{ Status = 'Fail'; Message = 'The default password policy has weak settings.'; Details = $fail + $warn }
        }
        if ($warn.Count -gt 0) {
            return @{ Status = 'Warning'; Message = 'The default password policy is below recommended values.'; Details = $warn }
        }
        return @{ Status = 'Pass'; Message = "Minimum length $($policy.MinPasswordLength), complexity on, history $($policy.PasswordHistoryCount), lockout after $($policy.LockoutThreshold) attempts." }
    }
}
