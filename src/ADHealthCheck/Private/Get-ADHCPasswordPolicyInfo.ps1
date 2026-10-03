function Get-ADHCPasswordPolicyInfo {
    <#
    .SYNOPSIS
        Collects the default domain password and lockout policy.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([hashtable] $Connection = @{})

    $policy = Get-ADDefaultDomainPasswordPolicy @Connection -ErrorAction Stop
    [pscustomobject]@{
        MinPasswordLength           = [int]$policy.MinPasswordLength
        ComplexityEnabled           = [bool]$policy.ComplexityEnabled
        PasswordHistoryCount        = [int]$policy.PasswordHistoryCount
        LockoutThreshold            = [int]$policy.LockoutThreshold
        ReversibleEncryptionEnabled = [bool]$policy.ReversibleEncryptionEnabled
        MaxPasswordAgeDays          = [int]([timespan]$policy.MaxPasswordAge).TotalDays
    }
}
