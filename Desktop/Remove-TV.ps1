<#
.Synopsis
Removes the stored permanent password for Teamviewer 10
#>

$OSArch = Get-WmiObject win32_operatingsystem | Select-Object osarchitecture
$OSArch = $OSArch.osarchitecture


If ($OSArch -eq "64-bit") {
	$TVLoc = "HKLM:\Software\WOW6432Node\Teamviewer"
}

If ($OSArch -eq "32-bit") {
	$TVLoc = "HKLM:\Software\Teamviewer"
}

$TVKey = Get-ItemProperty $TVLoc
$TVAccKey = Get-ItemProperty "$TVLoc\AccessControl"

$TVPermPass = $TVKey.PermanentPassword
$TVOwner = $TVKey.OwningManagerAccountName
$TVAcceptInbound = $TVKey.Security_AcceptIncoming
$TVAccControlType = $TVAccKey.AC_Server_AccessControlType

If ($TVPermPass) {
	Remove-ItemProperty -Path $TVLoc -Name "PermanentPassword"
	Remove-ItemProperty -Path $TVAccLoc -Name "PermanentPasswordDate"
}

If ($TVOwner) {
	Remove-ItemProperty -Path $TVLoc -Name "OwningManagerAccountName"
	Remove-ItemProperty -Path $TVLoc -Name "OwningManagerCompanyName"
}

If (($TVAcceptInbound -ne "0") -AND ($NULL -ne $TVAcceptInbound)) {
	Remove-ItemProperty -Path $TVLoc -Name "Security_AcceptIncoming"
	$TVAcceptInbound = $NULL	
}

If (($TVAccControlType -ne "10") -AND ($NULL -ne $TVAccControlType)) {
	Remove-ItemProperty -Path $TVAccLoc -Name "AC_Server_AccessControlType"
	$TVAccControlType = $NULL
}

if ((!$TVAcceptInbound) -AND (!$TVAccControlType)) {
	New-ItemProperty -Path "HKLM:\Software\WOW6432Node\Teamviewer" -Name "Security_AcceptIncoming" -Value "0" -PropertyType DWORD
	New-ItemProperty -Path "HKLM:\Software\WOW6432Node\Teamviewer" -Name "PermanentPasswordDate" -Value "20181128T114036" -PropertyType String
	New-ItemProperty -Path "HKLM:\Software\WOW6432Node\Teamviewer\AccessControl" -Name "AC_Server_AccessControlType" -Value "10" -PropertyType DWORD
}

Restart-Service -Name TeamViewer