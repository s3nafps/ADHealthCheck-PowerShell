@{
    Id             = 'ADHC-INF-005'
    Category       = 'Infrastructure'
    Title          = 'Domain controller and Global Catalog redundancy'
    Severity       = 'High'
    Description    = 'A domain with one writable domain controller or one Global Catalog has no tolerance for a failed server.'
    Recommendation = 'Run at least two writable domain controllers per domain and make at least two of them Global Catalogs.'
    References     = @('https://learn.microsoft.com/windows-server/identity/ad-ds/plan/planning-domain-controller-placement')
    Requires       = @('DomainControllers')
    Test           = {
        param($Context)
        $writable = @($Context.Data.DomainControllers | Where-Object { -not $_.IsReadOnly })
        $gc = @($Context.Data.DomainControllers | Where-Object { $_.IsGlobalCatalog })
        $problems = @()
        if ($writable.Count -lt 2) { $problems += "Writable domain controllers: $($writable.Count)" }
        if ($gc.Count -lt 2) { $problems += "Global Catalog servers: $($gc.Count)" }
        if ($problems.Count -gt 0) {
            return @{ Status = 'Fail'; Message = 'The domain has a single point of failure.'; Details = $problems }
        }
        return @{ Status = 'Pass'; Message = "$($writable.Count) writable domain controllers and $($gc.Count) Global Catalogs." }
    }
}
