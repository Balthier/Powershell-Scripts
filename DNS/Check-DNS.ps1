<#
.Synopsis
Checks Google's DNS for the specified DNS name and waits until it appears
#>

$dns = Read-host "DNS"
$count = 0
$windowsVersion = Get-WmiObject win32_operatingSystem | Select-Object -ExpandProperty caption
$ErrorActionPreference = 'SilentlyContinue'

While (!$response) {
	Write-Host "`n"
	If ($windowsVersion -eq "Microsoft Windows 7 Professional ") {
		$server1 = [System.Net.Dns]::GetHostAddresses("$dns")
	}
	If ($windowsVersion -eq "Microsoft Windows 10 Pro") {
		$server1 = Resolve-DnsName -Name "$dns" -Server 8.8.8.8 -ErrorAction SilentlyContinue
	}
	If ($NULL -ne $server1) {
		Write-Host "DNS Entry Found"
		$type = $server1.Type
		if ($type -eq "A") {
			$address = $server1.IPAddress
		}
		if ($type -eq "CNAME") {
			$type = $type[0]
			$address = $server1[0].NameHost
		}
		Write-Host "$dns resolves as $type record, and points to $address"
		
	}
	Else {
		Write-Host "DNS Entry Not Found" -ForegroundColor "Red"
	}
	If ($NULL -ne $server1) {
		$count++
		Write-Host "Successful Check: $count / 10"
		$server1 = $NULL
	}
	Else {
		if ($count) {
			Write-Host "Check failed. Resetting counter."
			$count = 0
		}
	}
	If ($count -eq "10") {
		$response = $true
	}
	Start-Sleep -s 60
}