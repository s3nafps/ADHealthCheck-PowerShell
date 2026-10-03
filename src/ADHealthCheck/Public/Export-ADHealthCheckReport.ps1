function Export-ADHealthCheckReport {
    <#
    .SYNOPSIS
        Writes a report to HTML and/or JSON files.
    .DESCRIPTION
        The HTML report is a single self-contained file with no external scripts,
        fonts or stylesheets, so it can be opened on an air-gapped admin host or
        attached to a ticket. The JSON report contains the same results for
        dashboards, diffing between runs, or ingestion into a SIEM.
    .PARAMETER Report
        The object returned by Invoke-ADHealthCheck.
    .PARAMETER Path
        Folder to write to. Created if it does not exist.
    .PARAMETER Format
        Html, Json, or both.
    .PARAMETER BaseName
        File name without extension. Defaults to ADHealthCheck_<domain>_<timestamp>.
    .EXAMPLE
        Invoke-ADHealthCheck | Export-ADHealthCheckReport -Path .\reports -Format Html
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object] $Report,

        [Parameter(Mandatory)]
        [string] $Path,

        [ValidateSet('Html', 'Json')]
        [string[]] $Format = @('Html', 'Json'),

        [string] $BaseName
    )

    process {
        $folder = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
        if (-not (Test-Path -Path $folder) -and $PSCmdlet.ShouldProcess($folder, 'Create report folder')) {
            $null = New-Item -Path $folder -ItemType Directory -Force -WhatIf:$false
        }
        if (-not $BaseName) {
            $safeDomain = ($Report.Domain -replace '[^A-Za-z0-9.-]', '_')
            $BaseName = 'ADHealthCheck_{0}_{1}' -f $safeDomain, (Get-Date -Format 'yyyyMMdd-HHmmss')
        }

        if ($Format -contains 'Json') {
            $file = Join-Path -Path $folder -ChildPath "$BaseName.json"
            if ($PSCmdlet.ShouldProcess($file, 'Write JSON report')) {
                $Report | Select-Object -Property * -ExcludeProperty ReportFiles |
                    ConvertTo-Json -Depth 8 | Set-Content -Path $file -Encoding UTF8
                Get-Item -Path $file
            }
        }
        if ($Format -contains 'Html') {
            $file = Join-Path -Path $folder -ChildPath "$BaseName.html"
            if ($PSCmdlet.ShouldProcess($file, 'Write HTML report')) {
                ConvertTo-ADHCHtml -Report $Report | Set-Content -Path $file -Encoding UTF8
                Get-Item -Path $file
            }
        }
    }
}
