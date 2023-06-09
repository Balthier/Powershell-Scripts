Function connectAD($ADServer, [PSCredential]$Creds, $eLevel, $wLevel) {
	Write-Host "`n"
	Write-Host "Opening connection to $ADServer"
	$session = new-pssession -computer $ADServer -Credential $Creds -ErrorAction $eLevel -WarningAction $wLevel
	Invoke-Command -Session $session -ScriptBlock { Import-Module "C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\ADSync.psd1" -DisableNameChecking } -ErrorAction $eLevel -WarningAction $wLevel
	Import-PSSession -session $session -module ActiveDirectory -AllowClobber -DisableNameChecking -ErrorAction $eLevel -WarningAction $wLevel
	return $session
}

Function disconnectAD($session) {
	Write-Host "`n"
	Write-Host "Closing connection to $ADServer..."
	Remove-PSSession $session
}

Function connectO365([PSCredential]$Creds, $eLevel, $wLevel) {
	Write-Host "`n"
	Write-Host "Opening connection to Office 365"
	$O365Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Creds -Authentication Basic -AllowRedirection -ErrorAction $eLevel -WarningAction $wLevel
	Import-PSSession -session $O365Session -AllowClobber -DisableNameChecking -ErrorAction $eLevel -WarningAction $wLevel
	Connect-MsolService -Credential $Creds -ErrorAction $eLevel -WarningAction $wLevel
	return $O365Session
}

Function disconnectO365($O365Session) {
	Write-Host "`n"
	Write-Host "Closing connection to Office 365..."
	Remove-PSSession $O365Session
}

Function getDefaults() {
	$wLevel = "SilentlyContinue"
	$eLevel = "Stop"
	$EmailDomain = "COMPANY.COM"
	$Domain = "COMPANY.DOMAIN.LOCAL"
	$CurrentUser = $env:UserName
	[PSCredential]$Creds = Get-Credential -Credential "$CurrentUser@$EmailDomain"
	$ADServer = "Active-Directory-Server-01"
	return $wLevel, $eLevel, $EmailDomain, $Domain, $CurrentUser, $Creds, $ADServer
}
