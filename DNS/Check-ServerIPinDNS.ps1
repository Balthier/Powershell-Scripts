<#
.Synopsis
Takes a server list in C:\Temp\Servers.txt, and checks each DHCP scope settings to see if the servers are set as DNS Servers, and outputs to csv: C:\Temp\DNS.csv
#>


$DHCPServer = "DHCP-Server"
Write-Host "Getting Servers, and DHCP Scopes..."
$ServerList = Get-Content "C:\Temp\Servers.txt"
$ScopeList = Get-DHCPServerv4Scope -ComputerName $DHCPServer

$count = 0
$ArrayResults = @()
ForEach ($Scope in $ScopeList) {
	$ScopeID = $Scope.ScopeID
	$Count++
	$Total = $ScopeList.length
	[decimal]$Progress = ($Count / $Total) * 100
	$ProgressBar = [math]::floor($Progress)
	Write-Progress -Activity "Getting DNS references for scope $ScopeID..." -Status "Progress: $Count / $Total ($ProgressBar %)" -PercentComplete $ProgressBar
	$DNSIPs = Get-DhcpServerv4OptionValue -ComputerName $DHCPServer -ScopeId $ScopeID | Where-Object OptionId -eq 6 | Select-Object -ExpandProperty Value
	If ($DNSIPs) {
		$ArrayAdd = New-Object PSObject
		$ArrayAdd | Add-Member -MemberType NoteProperty -Name "ID" -Value $ScopeID
		$ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNSIPs" -Value $DNSIPs
		$ArrayResults += $ArrayAdd
	}
	$DNSIPs = $NULL
}
$DHCPDNSResults = $ArrayResults

$count = 0
$ArrayResults = @()
ForEach ($Server in $ServerList) {
	$Count++
	$Total = $ServerList.length
	[decimal]$Progress = ($Count / $Total) * 100
	$ProgressBar = [math]::floor($Progress)
	Write-Progress -Activity "Getting IP(s) for $Server..." -Status "Progress: $Count / $Total ($ProgressBar %)" -PercentComplete $ProgressBar
	$ServerIP = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Server | Select-Object -ExpandProperty ipaddress
	If ($ServerIP) {
		$ArrayAdd = New-Object PSObject
		$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Server" -Value $Server
		$ArrayAdd | Add-Member -MemberType NoteProperty -Name "IPAddress" -Value $ServerIP
		$ArrayResults += $ArrayAdd
	}
	$ServerIP = $NULL
}
$ServerIPResults = $ArrayResults

$ArrayResults = @()
ForEach ($ServerIPDetails in $ServerIPResults) {
	$Server = $ServerIPDetails.Server
	$ServerIP = $ServerIPDetails.IPAddress
	ForEach ($DNSIPDetails in $DHCPDNSResults) {
		$ScopeID = $DNSIPDetails.ID
		$DNSIPs = $DNSIPDetails.DNSIPs
		If ($ServerIP -IN $DNSIPs) {
			$ofs = "`n"
			[string]$DNSIPString = $DNSIPs
			$ArrayAdd = New-Object PSObject
			$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Server" -Value $Server
			$ArrayAdd | Add-Member -MemberType NoteProperty -Name "IPAddress" -Value $ServerIP
			$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Scope" -Value $ScopeID
			$ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS IPs" -Value $DNSIPString
			$ArrayResults += $ArrayAdd
			$ofs = " "
		}
	}
}
If ($ArrayResults) {
	$ArrayResults | Export-CSV "C:\Temp\DNS.csv" -NoTypeInformation
}
Else {
	Write-Host "No Results"
}