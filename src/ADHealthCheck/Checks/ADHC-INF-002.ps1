@{
    Id             = 'ADHC-INF-002'
    Category       = 'Infrastructure'
    Title          = 'FSMO roles are held by existing domain controllers'
    Severity       = 'High'
    Description    = 'Every FSMO role must be held by a domain controller that still exists. Roles left on a removed DC break RID allocation, schema changes, password changes and time sync.'
    Recommendation = 'Transfer the role to a healthy DC with Move-ADDirectoryServerOperationMasterRole, or seize it if the old holder is permanently gone.'
    References     = @('https://learn.microsoft.com/troubleshoot/windows-server/active-directory/transfer-or-seize-operation-master-roles-in-ad-ds')
    Requires       = @('Domain', 'Forest', 'DomainControllers')
    Test           = {
        param($Context)
        $known = @($Context.Data.DomainControllers | ForEach-Object { $_.HostName.ToLowerInvariant() })
        $roles = [ordered]@{
            PDCEmulator          = $Context.Data.Domain.PDCEmulator
            RIDMaster            = $Context.Data.Domain.RIDMaster
            InfrastructureMaster = $Context.Data.Domain.InfrastructureMaster
            SchemaMaster         = $Context.Data.Forest.SchemaMaster
            DomainNamingMaster   = $Context.Data.Forest.DomainNamingMaster
        }
        $orphaned = @()
        foreach ($role in $roles.Keys) {
            $holder = [string]$roles[$role]
            $isForestRole = @('SchemaMaster', 'DomainNamingMaster') -contains $role
            $inThisDomain = $holder.ToLowerInvariant().EndsWith('.' + $Context.DomainName.ToLowerInvariant())
            if ($isForestRole -and -not $inThisDomain) { continue }
            if ($known -notcontains $holder.ToLowerInvariant()) {
                $orphaned += "${role}: $holder"
            }
        }
        if ($orphaned.Count -gt 0) {
            return @{ Status = 'Fail'; Message = "$($orphaned.Count) FSMO role(s) point to a server that is not a current domain controller."; Details = $orphaned }
        }
        $holders = $roles.Keys | ForEach-Object { "${_}: $($roles[$_])" }
        return @{ Status = 'Pass'; Message = 'All FSMO roles are held by current domain controllers.'; Details = $holders; AffectedCount = 0 }
    }
}
