function Get-ADHCUserInfo {
    <#
    .SYNOPSIS
        Collects user accounts with the attributes the rules need.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param([hashtable] $Connection = @{})

    $properties = @(
        'LastLogonDate', 'PasswordLastSet', 'PasswordNeverExpires', 'PasswordNotRequired',
        'DoesNotRequirePreAuth', 'AllowReversiblePasswordEncryption', 'ServicePrincipalName',
        'AdminCount', 'AccountNotDelegated', 'userAccountControl', 'SID'
    )
    $useDesKeyOnly = 0x200000

    foreach ($user in (Get-ADUser -Filter * -Properties $properties @Connection -ErrorAction Stop)) {
        [pscustomobject]@{
            SamAccountName                    = [string]$user.SamAccountName
            DistinguishedName                 = [string]$user.DistinguishedName
            Sid                               = [string]$user.SID
            Enabled                           = [bool]$user.Enabled
            LastLogonDate                     = $user.LastLogonDate
            PasswordLastSet                   = $user.PasswordLastSet
            PasswordNeverExpires              = [bool]$user.PasswordNeverExpires
            PasswordNotRequired               = [bool]$user.PasswordNotRequired
            DoesNotRequirePreAuth             = [bool]$user.DoesNotRequirePreAuth
            AllowReversiblePasswordEncryption = [bool]$user.AllowReversiblePasswordEncryption
            UseDesKeyOnly                     = (([int]$user.userAccountControl -band $useDesKeyOnly) -ne 0)
            ServicePrincipalName              = @($user.ServicePrincipalName | ForEach-Object { [string]$_ })
            AdminCount                        = [int]$user.AdminCount
            AccountNotDelegated               = [bool]$user.AccountNotDelegated
        }
    }
}
