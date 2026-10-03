function Test-ADHCTcpPort {
    <#
    .SYNOPSIS
        Returns $true when a TCP connection to ComputerName:Port succeeds within the timeout.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName,

        [Parameter(Mandatory)]
        [int] $Port,

        [int] $TimeoutMilliseconds = 1500
    )

    $client = New-Object -TypeName System.Net.Sockets.TcpClient
    try {
        $connect = $client.BeginConnect($ComputerName, $Port, $null, $null)
        if (-not $connect.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
            return $false
        }
        $client.EndConnect($connect)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}
