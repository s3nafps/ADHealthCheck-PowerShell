@{
    Id             = 'ADHC-LAPS-001'
    Category       = 'Endpoint'
    Title          = 'LAPS coverage of workstations and member servers'
    Severity       = 'High'
    Description    = 'Without LAPS, local administrator passwords are often identical across machines, so one compromised host gives lateral movement to all of them.'
    Recommendation = 'Deploy Windows LAPS through Group Policy or Intune to every workstation and member server, and restrict who can read the passwords.'
    References     = @('https://learn.microsoft.com/windows-server/identity/laps/laps-overview')
    Requires       = @('Computers', 'LapsSchema')
    Test           = {
        param($Context)
        if ($Context.Data.LapsSchema -eq 'None') {
            return @{ Status = 'Fail'; Message = 'Neither Windows LAPS nor legacy LAPS attributes exist in the schema.' }
        }
        $targets = @($Context.Data.Computers | Where-Object { $_.Enabled -and -not $_.IsDomainController })
        if ($targets.Count -eq 0) {
            return @{ Status = 'Pass'; Message = 'There are no enabled workstations or member servers to cover.' }
        }
        $missing = @($targets | Where-Object { -not $_.HasLaps } | ForEach-Object { $_.Name })
        $coverage = [math]::Round(100 * ($targets.Count - $missing.Count) / $targets.Count, 1)
        $message = "LAPS manages $coverage% of $($targets.Count) computer(s) ($($Context.Data.LapsSchema))."
        if ($coverage -lt $Context.Settings.LapsCoverageFailurePercent) {
            return @{ Status = 'Fail'; Message = $message; Details = $missing }
        }
        if ($coverage -lt $Context.Settings.LapsCoverageWarningPercent) {
            return @{ Status = 'Warning'; Message = $message; Details = $missing }
        }
        return @{ Status = 'Pass'; Message = $message; Details = $missing }
    }
}
