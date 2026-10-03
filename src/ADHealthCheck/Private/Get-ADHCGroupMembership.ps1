function Get-ADHCGroupMembership {
    <#
    .SYNOPSIS
        Collects recursive membership of privileged groups and Protected Users.
    .OUTPUTS
        Hashtable of group name to an array of member objects. Groups that do not
        exist in the domain map to $null so rules can tell "empty" from "absent".
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string[]] $GroupName,

        [hashtable] $Connection = @{}
    )

    $result = @{}
    foreach ($name in (@($GroupName) + 'Protected Users' | Select-Object -Unique)) {
        try {
            $group = Get-ADGroup -Identity $name @Connection -ErrorAction Stop
        }
        catch {
            $result[$name] = $null
            continue
        }
        $members = Get-ADGroupMember -Identity $group -Recursive @Connection -ErrorAction Stop
        $result[$name] = @(foreach ($member in $members) {
                [pscustomobject]@{
                    SamAccountName    = [string]$member.SamAccountName
                    ObjectClass       = [string]$member.objectClass
                    DistinguishedName = [string]$member.DistinguishedName
                }
            })
    }
    return $result
}
