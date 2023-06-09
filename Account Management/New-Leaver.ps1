<#
.Synopsis
Processes a new Leaver by disabling AD accounts, and removing O365 licenses

.Notes
Author: Balthier Lionheart
#>

# Find the current location of the script
$scriptPath = Split-Path -Parent $PSCommandPath
Set-Location $scriptPath

# Include the functions
. "..\Shared\Common-Functions.ps1"
. "..\Shared\AD-Functions.ps1"

# Set custom colour scheme
setColourScheme

##############
## Messages ##
##############
$Advisary01 = "
Please make sure you have the following information before proceeding:
Email Address

If you are missing this information, DO NOT continue."
$Advisary02 = "
The following changes can cause serious issues, including data loss, if done accidentally.

If you are unsure about anything, DO NOT continue."

Write-Host "$Advisary01" -ForegroundColor "Yellow"
$Ad01Continue = Read-Host "Continue? (Y/N)"
While ("Y", "N", "Yes", "No" -notcontains $Ad01Continue) { 
	$Ad01Continue = Read-Host "Continue? (Y/N)"
}

if ("Y", "Yes" -contains $Ad01Continue) {
	######################
	## System Variables ##
	######################
	$defaults = getDefaults
	$wLevel = $defaults[0]
	$eLevel = $defaults[1]
	[PSCredential]$Creds = $defaults[5]
	$ADServer = $defaults[6]
	Do {
		$email = Read-host "E-Mail Address" 	
	} until ($email -Match '^([\w.]+)*(@DOMAIN\.TLD)')
	
	# Connect to Active Directory
	$session = connectAD $ADServer $Creds $eLevel $wLevel
	$session = $session[1]
	
	# Connect to Office 365
	$O365Session = connectO365 $Creds $eLevel $wLevel
	$O365Session = $O365Session[1]
	
	Write-Host "`n"
	Write-Host "Searching for Office 365 mailbox..."
	$O365match = Get-Mailbox -identity "$email" -ErrorAction SilentlyContinue
	if ($O365match) {
		Write-Host "`n"
		Write-Host "Office 365 account found!" -ForegroundColor "Cyan"
		$O365match
		$O365MatchValue = $TRUE
	}
	else {
		Clear-Variable $O365MatchValue
		Write-Host "No Office 365 account found!" -ForegroundColor "Red"
	}
	
	Write-Host "`n"
	Write-Host "Searching for Active Directory account..."
	$filter = [scriptblock]::Create("EmailAddress -eq '$email'")
	$ADMatch = Get-ADUser -Filter $filter
	if ($ADMatch) {
		Write-Host "`n"
		Write-Host "Active Directory account found!" -ForegroundColor "Cyan"
		$ADMatch
		$ADMatchValue = $TRUE
	}
	else {
		Clear-Variable $ADMatchValue
		Write-Host "No Active Directory account found!" -ForegroundColor "Red"
	}
	
	Write-Host "$Advisary02" -ForegroundColor "Yellow"
	Write-Host "`n"
	Write-Host "Accounts listed above will now be disabled and/or deleted"
	
	$Ad02Continue = Read-Host "Continue? (Y/N)"
	While ("Y", "N", "Yes", "No" -notcontains $Ad02Continue) { 
		$Ad02Continue = Read-Host "Continue? (Y/N)"
	}
	if ("Yes", "Y" -contains $Ad02Continue) {
		if ($O365MatchValue) {
			Write-Host "`n"
			Write-Host "Setting mailbox to be shared..."
			Set-Mailbox $email -Type Shared
			$O365User = Get-MsolUser -UserPrincipalName "$email"
			$UserLicensed = $O365User.isLicensed
			if ($UserLicensed) {
				$licenses = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -like "*O365_BUSINESS_PREMIUM*" }
				$LicenseID = $licenses.AccountSkuId
				Write-Host "`n"
				Write-Host "Removing Office 365 license..."
				Set-MsolUserLicense -UserPrincipalName "$email" -RemoveLicenses "$LicenseID"
			}
			else {
				Write-Host "`n"
				Write-Host "User not licensed on Office 365... Skipping..."
			}
		}
		if ($ADMatchValue) {
			Write-Host "`n"
			Write-Host "Disabling Active Directory account..."
			$ADSamAccount = $ADMatch.SamAccountName
			Disable-ADAccount -identity "$ADSamAccount"
			Write-Host "`n"
			Write-Host "Forcing Active Directory sync to Office 365..."
			$sync = Invoke-Command -Session $session -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta } -ErrorAction $eLevel
			$syncValue = $sync.Result
			Write-Host "`n"
			Write-Host "AD -> O365 sync result: $syncValue!"
		}
	}
	
	# Disconnect from Active Directory
	disconnectAD $session
	
	# Disconnect from Office 365
	disconnectO365 $O365Session
}