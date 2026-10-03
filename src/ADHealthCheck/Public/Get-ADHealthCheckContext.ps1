function Get-ADHealthCheckContext {
    <#
    .SYNOPSIS
        Collects the Active Directory data that the rules evaluate.
    .DESCRIPTION
        Runs each collector once and stores the normalized results in a context
        object. A collector that fails is recorded in Errors and only the rules that
        depend on it are affected. The context can be saved and evaluated later with
        Invoke-ADHealthCheckRule or Invoke-ADHealthCheck -Context.
    .PARAMETER Server
        Domain controller or domain to query. Defaults to the computer's domain.
    .PARAMETER Credential
        Credential used for the AD queries.
    .PARAMETER Settings
        Hashtable of threshold overrides, for example @{ StaleUserDays = 60 }.
    .PARAMETER ConfigurationPath
        Path to a .psd1 file with threshold overrides.
    .PARAMETER SkipNetworkCheck
        Skips the DNS SRV and TCP port checks, for example when running from a host
        that cannot reach every domain controller.
    .EXAMPLE
        $context = Get-ADHealthCheckContext -Server dc01.contoso.com
        Invoke-ADHealthCheckRule -Context $context -Category Kerberos
    #>
    [CmdletBinding()]
    [OutputType('ADHealthCheck.Context')]
    param(
        [string] $Server,

        [System.Management.Automation.PSCredential] $Credential,

        [hashtable] $Settings,

        [string] $ConfigurationPath,

        [switch] $SkipNetworkCheck
    )

    if (-not (Get-Command -Name Get-ADDomain -ErrorAction SilentlyContinue)) {
        try {
            Import-Module -Name ActiveDirectory -ErrorAction Stop -Verbose:$false
        }
        catch {
            throw 'The ActiveDirectory module is required. Install RSAT: Active Directory Domain Services tools, or run on a domain controller.'
        }
    }

    $resolvedSettings = Get-ADHCSetting -ConfigurationPath $ConfigurationPath -Settings $Settings
    $connection = Get-ADHCConnectionParameter -Server $Server -Credential $Credential

    $data = @{}
    $errors = @{}
    $skipped = @{}
    $timings = [ordered]@{}

    $collect = {
        param([string] $Name, [scriptblock] $Collector)
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            Write-Verbose "Collecting $Name"
            $data[$Name] = & $Collector
        }
        catch {
            $errors[$Name] = $_.Exception.Message
            Write-Warning "Could not collect ${Name}: $($_.Exception.Message)"
        }
        $timings[$Name] = [math]::Round($watch.Elapsed.TotalSeconds, 2)
    }

    $domainInfo = Get-ADHCDomainInfo -Connection $connection
    $data.Domain = $domainInfo.Domain
    $data.Forest = $domainInfo.Forest
    $domainName = $data.Domain.DNSRoot

    & $collect 'DomainControllers' { @(Get-ADHCDomainControllerInfo -Connection $connection) }
    & $collect 'Users' { @(Get-ADHCUserInfo -Connection $connection) }
    & $collect 'Computers' {
        $computerInfo = Get-ADHCComputerInfo -Connection $connection
        $data.LapsSchema = $computerInfo.LapsSchema
        $computerInfo.Computers
    }
    & $collect 'Groups' { Get-ADHCGroupMembership -GroupName $resolvedSettings.PrivilegedGroups -Connection $connection }
    & $collect 'Replication' { Get-ADHCReplicationInfo -DomainName $domainName -Connection $connection }
    & $collect 'PasswordPolicy' { Get-ADHCPasswordPolicyInfo -Connection $connection }
    & $collect 'RecycleBin' { Get-ADHCRecycleBinInfo -Connection $connection }

    if (Get-Command -Name Get-GPO -ErrorAction SilentlyContinue) {
        & $collect 'Gpos' { @(Get-ADHCGpoInfo -DomainName $domainName -DomainDistinguishedName $data.Domain.DistinguishedName -Connection $connection) }
    }
    else {
        $skipped.Gpos = 'The GroupPolicy module is not installed (RSAT: Group Policy Management Tools).'
    }

    if ($SkipNetworkCheck) {
        $skipped.DnsSrv = 'Network checks were skipped (-SkipNetworkCheck).'
        $skipped.Ports = 'Network checks were skipped (-SkipNetworkCheck).'
    }
    elseif ($data.ContainsKey('DomainControllers')) {
        $hostNames = @($data.DomainControllers | ForEach-Object { $_.HostName })
        if (Get-Command -Name Resolve-DnsName -ErrorAction SilentlyContinue) {
            & $collect 'DnsSrv' { Get-ADHCDnsSrvInfo -DomainName $domainName -DomainControllerHostName $hostNames }
        }
        else {
            $skipped.DnsSrv = 'Resolve-DnsName is not available on this host.'
        }
        & $collect 'Ports' {
            @(Get-ADHCPortInfo -DomainControllerHostName $hostNames -Port $resolvedSettings.DomainControllerPorts -TimeoutMilliseconds $resolvedSettings.PortTimeoutMilliseconds)
        }
    }

    [pscustomobject]@{
        PSTypeName  = 'ADHealthCheck.Context'
        DomainName  = $domainName
        ForestName  = $data.Forest.Name
        Server      = $Server
        CollectedAt = (Get-Date).ToUniversalTime()
        Now         = Get-Date
        Settings    = $resolvedSettings
        Data        = $data
        Errors      = $errors
        Skipped     = $skipped
        Timings     = $timings
    }
}
