<#
.Synopsis
Checks DNS to ensure the Server/IP combination is correct
#>


$Servers = @{
    "Server1" = "ServerIP1"
    "Server2" = "ServerIP1"
}
$Servers.GetEnumerator() | ForEach-Object {
    $ServerName = $_.Key
    $ServerIP = $_.Value

    Clear-DnsClientCache
    $IPCheck = (Test-Connection -ComputerName $ServerName -Count 1).IPV4Address.IPAddressToString

    While ($IPCheck -ne $ServerIP) {
        Write-Warning "$ServerName reporting incorrect IP: $IPCheck Expected: $ServerIP"
        Start-Sleep -Seconds 120 -Verbose
        Clear-DnsClientCache -Verbose
        $IPCheck = (Test-Connection -ComputerName $ServerName -Count 1).IPV4Address.IPAddressToString
        $PreviousIP = $IPCheck
    }
    If ($PreviousIP) {
        Write-Host "Success! $ServerName is now reporting: $ServerIP Previously: $PreviousIP"
    }
    Else {
        Write-Host "Success! $ServerName is now reporting: $ServerIP"
    }
    Clear-Variable -Name PreviousIP
}