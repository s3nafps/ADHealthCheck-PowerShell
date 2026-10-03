function Get-ADHCPortInfo {
    <#
    .SYNOPSIS
        Tests the core AD service ports on each domain controller.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory)]
        [string[]] $DomainControllerHostName,

        [Parameter(Mandatory)]
        [int[]] $Port,

        [int] $TimeoutMilliseconds = 1500
    )

    foreach ($hostName in $DomainControllerHostName) {
        foreach ($number in $Port) {
            [pscustomobject]@{
                DomainController = $hostName
                Port             = $number
                Open             = Test-ADHCTcpPort -ComputerName $hostName -Port $number -TimeoutMilliseconds $TimeoutMilliseconds
            }
        }
    }
}
