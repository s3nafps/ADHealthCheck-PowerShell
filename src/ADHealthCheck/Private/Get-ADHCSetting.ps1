function Get-ADHCSetting {
    <#
    .SYNOPSIS
        Merges default thresholds, an optional .psd1 file and an optional hashtable.
    .DESCRIPTION
        Later sources win: defaults < ConfigurationPath < Settings. Unknown keys are
        rejected so a typo cannot silently fall back to a default.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string] $ConfigurationPath,

        [hashtable] $Settings
    )

    $defaultPath = Join-Path -Path $script:ModuleRoot -ChildPath 'Config/Default.psd1'
    $merged = Import-PowerShellDataFile -Path $defaultPath

    $overrides = @()
    if ($ConfigurationPath) {
        if (-not (Test-Path -Path $ConfigurationPath -PathType Leaf)) {
            throw "Configuration file '$ConfigurationPath' was not found."
        }
        $overrides += , (Import-PowerShellDataFile -Path $ConfigurationPath)
    }
    if ($Settings) {
        $overrides += , $Settings
    }

    foreach ($override in $overrides) {
        foreach ($key in $override.Keys) {
            if (-not $merged.ContainsKey($key)) {
                throw "Unknown setting '$key'. Valid settings: $(($merged.Keys | Sort-Object) -join ', ')."
            }
            $merged[$key] = $override[$key]
        }
    }

    return $merged
}
