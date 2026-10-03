@{
    Id             = 'ADHC-INF-004'
    Category       = 'Infrastructure'
    Title          = 'Domain controller operating systems are supported'
    Severity       = 'High'
    Description    = 'Domain controllers on an operating system without security updates are a direct path to domain compromise.'
    Recommendation = 'Replace unsupported domain controllers with Windows Server 2019 or later and plan upgrades for versions nearing end of support.'
    References     = @('https://learn.microsoft.com/lifecycle/products/?products=windows')
    Requires       = @('DomainControllers')
    Test           = {
        param($Context)
        $unsupported = @()
        $nearing = @()
        foreach ($dc in $Context.Data.DomainControllers) {
            $os = $dc.OperatingSystem
            if ($os -match '2000|2003|2008|2012') {
                $unsupported += "$($dc.HostName): $os"
            }
            elseif ($os -match '2016') {
                $nearing += "$($dc.HostName): $os (extended support ends January 2027)"
            }
        }
        if ($unsupported.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($unsupported.Count) domain controller(s) run an unsupported operating system."; Details = $unsupported + $nearing; AffectedCount = $unsupported.Count }
        }
        if ($nearing.Count -gt 0) {
            return @{ Status = 'Warning'; Message = "$($nearing.Count) domain controller(s) run an operating system nearing end of support."; Details = $nearing }
        }
        return @{ Status = 'Pass'; Message = 'All domain controllers run a supported operating system.' }
    }
}
