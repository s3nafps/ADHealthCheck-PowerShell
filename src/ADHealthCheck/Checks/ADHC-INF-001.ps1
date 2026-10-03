@{
    Id             = 'ADHC-INF-001'
    Category       = 'Infrastructure'
    Title          = 'Domain and forest functional level'
    Severity       = 'Medium'
    Description    = 'Low functional levels block security features such as Protected Users enforcement, Kerberos armoring and the AD Recycle Bin.'
    Recommendation = 'Retire domain controllers running older Windows Server versions, then raise the domain and forest functional levels.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/active-directory-functional-levels')
    Requires       = @('Domain', 'Forest')
    Test           = {
        param($Context)
        $toNumber = {
            param([string] $Mode)
            if ($Mode -match 'Windows(\d{4})(R2)?') {
                $value = [double]$Matches[1]
                if ($Matches[2]) { $value += 0.5 }
                return $value
            }
            return 0
        }
        $minimum = & $toNumber $Context.Settings.MinimumFunctionalLevel
        $domainMode = $Context.Data.Domain.DomainMode
        $forestMode = $Context.Data.Forest.ForestMode
        $low = @()
        if ((& $toNumber $domainMode) -lt $minimum) { $low += "Domain functional level: $domainMode" }
        if ((& $toNumber $forestMode) -lt $minimum) { $low += "Forest functional level: $forestMode" }
        if ($low.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "Functional level is below $($Context.Settings.MinimumFunctionalLevel)."; Details = $low }
        }
        return @{ Status = 'Pass'; Message = "Domain ($domainMode) and forest ($forestMode) meet the minimum functional level." }
    }
}
