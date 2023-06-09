<#
.Synopsis
Processes a new Starter by creating an AD/O365 account, assigning a license, and sending a Welcome email

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

# Turn on logging to file
toggleLogging("On")

##############
## Messages ##
##############
$Advisary01 = "
Please make sure you have the following information before proceeding:
First Name
Surname
Job Title
Department

International (Do no use this script, yet!)

If you are missing any of this information, DO NOT continue."

$Error01 = "There is currently no available Office 365 licenses available. Please free up a license, and try again."

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
	$EmailDomain = $defaults[2]
	$Creds = $defaults[5]
	$ADServer = $defaults[6]
	$html = (Get-Content "$scriptPath\Welcome.html")
	
	# Connect to Active Directory
	$session = connectAD $ADServer $Creds $eLevel $wLevel
	$session = $session[1]
	# Connect to Office 365
	$O365Session = connectO365 $Creds $eLevel $wLevel
	$O365Session = $O365Session[1]
	
	####################
	## User Variables ##
	####################
	Do {
		$forename = Read-host "Forename (a-Z Only)" 
	} until ($forename -Match '^(\w|-)*$')

	Do {
		$surname = Read-host "Surname (a-Z Only)" 
	} until ($surname -Match '^(\w|-)*$')

	$password = "Autocab1" | ConvertTo-SecureString -AsPlainText -Force
	Do {
		$JobTitle = Read-Host "Job Title (a-Z, spaces, Only)" 
	} until ($JobTitle -Match '^(\w| )*$')

	Do {
		$Dept = Read-Host "Department (a-Z, spaces, Only)" 
	} until ($Dept -Match '^(\w| )*$')
	
	$f = $forename.Trim()
	$s = $surname.Trim()
	$jt = $JobTitle.Trim()
	$fn = $forename + " " + $surname
	$a = $f + "." + $s
	$email = "$a@$EmailDomain"
	$welcome = Read-Host "Welcome Email? (Y/N)"
	While ("Y", "N", "Yes", "No" -notcontains $welcome) { 
		$welcome = Read-Host "Welcome Email? (Y/N) "
	}
	# Create user in Active Directory
	Write-Host "`n"
	Write-Host "Creating Active Directory account..."
	New-ADUser -Name "$fn" -GivenName "$f" -Surname "$s" -SamAccountName "$a" -AccountPassword $password -UserPrincipalName "$email" -EmailAddress "$a@$EmailDomain" -Description "$jt" -Department "$Dept" -Path "OU=Users,DC=HQ,DC=DOMAIN,DC=LOCAL" -ChangePasswordAtLogon $True -Enabled $True -ErrorAction $eLevel
	# Force a Delta sync from AD to Azure AD
	Write-Host "`n"
	Write-Host "Forcing Active Directory sync to Office 365..."
	$sync = Invoke-Command -Session $session -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta } -ErrorAction $eLevel
	$syncValue = $sync.Result
	Write-Host "`n"
	Write-Host "AD -> O365 sync result: $syncValue!"
	
	# Disconnect from Active Directory
	disconnectAD $session
	
	# Base wait time, in minutes
	$WaitMins = 2
	# Convert to seconds
	$SleepTime = $WaitMins * 60
	# Calculate current time, plus base wait time
	$WaitTime = (get-date).AddMinutes($WaitMins).ToString("HH:mm")
	Write-Host "`n"
	Write-Host "Waiting $WaitMins minutes ($WaitTime) for account to appear on Office 365."
	# Pause the script for the specified minutes/seconds
	Start-Sleep $SleepTime
	# Check for the new account on Office 365
	$O365Account = get-MsolUser -UserPrincipalName "$email" -WarningAction $wLevel
	While (!$O365Account) {
		# While the account can't be located on Office 365, repeat the previous waiting process
		$WaitTime = (get-date).AddMinutes($WaitMins).ToString("HH:mm")
		Write-Host "`n"
		Write-Host "Account not found yet."
		Write-Host "Waiting $WaitMins minutes ($WaitTime) for account to appear on Office 365."
		Start-Sleep $SleepTime
		$O365Account = get-MsolUser -UserPrincipalName "$email" -WarningAction $wLevel
	}
	# Retrieve the Office 365 license information
	Write-Host "`n"
	Write-Host "Retrieving license details..."
	$licenses = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -like "*O365_BUSINESS_PREMIUM*" }
	# Calculate license availability
	$Available = $licenses.ActiveUnits - $licenses.ConsumedUnits
	if ($available) {
		# If no licenses are available, advise the Technician, and prompt to retry
		While ($available -eq 0) {
			Write-Host "`n"
			Write-Host "$Error01" -ForegroundColor "DarkRed"
			Write-Host "`n"
			$Err01Retry = Read-Host "Retry? (Y/N)"
			While ("Y", "N", "Yes", "No" -notcontains $Err01Retry) { 
				$Err01Retry = Read-Host "Retry? (Y/N) "
			}
			if ("Y", "Yes" -contains $Err01Retry) {
				$licenses = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -like "*O365_BUSINESS_PREMIUM*" }
				$Available = $licenses.ActiveUnits - $licenses.ConsumedUnits
			}
			else {
				exit
			}
		}
		# Retrieve the Office 365 License ID
		$LicenseID = $licenses.AccountSkuId
		Write-Host "`n"
		Write-Host "Current Office 365 licenses available: $available"
		# Confirm before assigning the license to the new user
		Write-Host "`n"
		$Cont01 = Read-Host "Assign license to "$fn"? (Y/N)"
		While ("Y", "N", "Yes", "No" -notcontains $Cont01) { 
			$Cont01 = Read-Host "Assign license to "$fn"? (Y/N)"
		}
		if ("Y", "Yes" -contains $Cont01) {
			Write-Host "`n"
			Write-Host "Assigning license to $fn..."
			# Set the user's location (Default: GB)
			Set-MsolUser -UserPrincipalName "$email" -UsageLocation "GB"
			# Assign the Office 365 license to the user
			Set-MsolUserLicense -UserPrincipalName "$email" -AddLicenses "$LicenseID"
			# Add the user to the main company distribution group (Default: UK)
			Write-Host "`n"
			Write-Host "Adding $fn to UK distribution group..."
			Add-DistributionGroupMember -Identity "UK" -Member "$email"
		}
	}
	if ("Y", "Yes" -contains $welcome) {
		$WaitTime = (get-date).AddMinutes($WaitMins).ToString("HH:mm")
		Write-Host "Waiting $WaitMins minutes ($WaitTime) for mailbox to appear on Office 365."
		Start-Sleep $SleepTime
		$O365MAccount = Get-Mailbox -Identity "$fn" -WarningAction $wLevel
		While (!$O365MAccount) {
			# While the account can't be located on Office 365, repeat the previous waiting process
			$WaitTime = (get-date).AddMinutes($WaitMins).ToString("HH:mm")
			Write-Host "Mailbox not found yet."
			Write-Host "Waiting $WaitMins minutes ($WaitTime) for mailbox to appear on Office 365."
			Start-Sleep $SleepTime
			$O365MAccount = Get-Mailbox -Identity "$fn" -WarningAction $wLevel
		}
		###############################
		## SMTP Connection Variables ##
		###############################
		$server = "OFFICE-365-SERVER"
		$from = "IT@COMPANY.COM"
		$subject = "Welcome to COMPANY"
		$to = "$email"
		$body = $ExecutionContext.InvokeCommand.ExpandString($html)
		# Send welcome email
		Send-MailMessage -SmtpServer $server -UseSsl -Credential $Creds -From "$from" -To "$to" -subject "$subject" -Body "$Body" -BodyAsHTML
	}
	
	# Disconnect from Office 365
	disconnectO365 $O365Session
}
toggleLogging("Off")			