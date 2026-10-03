function Get-ADHCComputerInfo {
    <#
    .SYNOPSIS
        Collects computer accounts, including whether a LAPS password is managed.
    .DESCRIPTION
        Windows LAPS (msLAPS-*) and legacy LAPS (ms-Mcs-*) attributes only exist when
        the schema was extended, so each is probed separately. The result carries a
        LapsSchema value describing which ones are present.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([hashtable] $Connection = @{})

    $base = @('LastLogonDate', 'OperatingSystem', 'TrustedForDelegation', 'PrimaryGroupID')
    $lapsAttributes = @{
        'Windows LAPS' = 'msLAPS-PasswordExpirationTime'
        'Legacy LAPS'  = 'ms-Mcs-AdmPwdExpirationTime'
    }

    $available = @()
    foreach ($name in $lapsAttributes.Keys) {
        try {
            $null = Get-ADComputer -Filter * -ResultSetSize 1 -Properties $lapsAttributes[$name] @Connection -ErrorAction Stop
            $available += $name
        }
        catch {
            Write-Verbose "LAPS attribute for $name is not in the schema: $($_.Exception.Message)"
        }
    }

    $properties = $base + @($available | ForEach-Object { $lapsAttributes[$_] })
    $computers = foreach ($computer in (Get-ADComputer -Filter * -Properties $properties @Connection -ErrorAction Stop)) {
        $hasLaps = $false
        foreach ($name in $available) {
            $attribute = $lapsAttributes[$name]
            if ($computer.PSObject.Properties[$attribute] -and $null -ne $computer.$attribute) {
                $hasLaps = $true
            }
        }
        [pscustomobject]@{
            Name                 = [string]$computer.Name
            DistinguishedName    = [string]$computer.DistinguishedName
            Enabled              = [bool]$computer.Enabled
            LastLogonDate        = $computer.LastLogonDate
            OperatingSystem      = [string]$computer.OperatingSystem
            TrustedForDelegation = [bool]$computer.TrustedForDelegation
            IsDomainController   = ([int]$computer.PrimaryGroupID -in @(516, 521))
            HasLaps              = $hasLaps
        }
    }

    $schema = switch ($available.Count) {
        0 { 'None' }
        2 { 'Both' }
        default { $available[0] }
    }

    [pscustomobject]@{
        Computers  = @($computers)
        LapsSchema = $schema
    }
}
