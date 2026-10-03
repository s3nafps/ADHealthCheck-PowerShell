function Get-ADHCPrivilegedMember {
    <#
    .SYNOPSIS
        Maps each user that belongs to a configured privileged group to the groups it is in.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [object] $Context
    )

    $map = @{}
    foreach ($groupName in $Context.Settings.PrivilegedGroups) {
        if (-not $Context.Data.Groups.ContainsKey($groupName) -or $null -eq $Context.Data.Groups[$groupName]) {
            continue
        }
        foreach ($member in $Context.Data.Groups[$groupName]) {
            if ($member.ObjectClass -ne 'user') { continue }
            if (-not $map.ContainsKey($member.SamAccountName)) {
                $map[$member.SamAccountName] = New-Object -TypeName System.Collections.Generic.List[string]
            }
            $map[$member.SamAccountName].Add($groupName)
        }
    }
    return $map
}
