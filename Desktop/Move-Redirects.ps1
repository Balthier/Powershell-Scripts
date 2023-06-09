<#
.Synopsis
This script will redirect "My Documents", "AppData", and "Desktop" to $FR\USERNAME\FOLDER

.Description
This script will redirect "My Documents", "AppData", and "Desktop" to $FR\USERNAME\FOLDER

Usage

Set the $FR variable to be the location that you want the folders to be redirected to, and then just run the .ps1 file in powershell. You will be prompted to choose which folders you want to be changed.

NOTE: When redirecting "My Documents", this script will also redirect "My Pictures", "My Videos", and "My Music". This is intentional, as these are still classed as system folders, which are currently situated in "My Documents".

.Notes
Author: Balthier Lionheart
Created: 2014-01-21
Modified: 2014-10-30
#>

# Determine which folders need to be redirected. Force the answer to be "Yes","Y","No", or "N"
$RoamAppData = Read-Host "Change AppData? (Y/N) "
While ("Y", "N", "Yes", "No" -notcontains $RoamAppData) { 
	$RoamAppData = Read-Host "Change AppData? (Y/N) "
}
$RoamDesktop = Read-Host "Change Desktop? (Y/N) "
While ("Y", "N", "Yes", "No" -notcontains $RoamDesktop) { 
	$RoamDesktop = Read-Host "Change Desktop? (Y/N) "
}
$RoamDocuments = Read-Host "Change Documents? (Y/N) "
While ("Y", "N", "Yes", "No" -notcontains $RoamDocuments) { 
	$RoamDocuments = Read-Host "Change Documents? (Y/N) "
}
# Set the registry location
$HKEY = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
# Set the folder redirect location
$FR = ""
# Get the current username
$UN = $env:username
#Get the current registry values for the redirects
$AppData = (Get-ItemProperty -Path $HKEY).AppData
$Desktop = (Get-ItemProperty -Path $HKEY).Desktop
$Documents = (Get-ItemProperty -Path $HKEY).Personal
$Pictures = (Get-ItemProperty -Path $HKEY)."My Pictures"
$Music = (Get-ItemProperty -Path $HKEY)."My Music"
$Videos = (Get-ItemProperty -Path $HKEY)."My Video"

# Show the current values to the user
Write-Host "Current Registry Values: "
Write-Host "App Data		: 	$AppData"
Write-Host "Desktop			: 	$Desktop"
Write-Host "Documents		: 	$Documents"
Write-Host "Pictures		:	$Pictures"
Write-Host "Music			: 	$Music"
Write-Host "Videos			: 	$Videos"

# Change only the variables of the entries that have been selected
If ("Y", "Yes" -contains $RoamAppData) {
	$AppData = "$FR\$UN\AppData"
}
If ("Y", "Yes" -contains $RoamDesktop) {
	$Desktop = "$FR\$UN\Desktop"
}
If ("Y", "Yes" -contains $RoamDocuments) {
	$Documents = "$FR\$UN\My Documents"
	$Pictures = "$FR\$UN\My Pictures"
	$Music = "$FR\$UN\My Music"
	$Videos = "$FR\$UN\My Video"
}
# Show the predicted values after registry changes
Write-Host "Proposed Registry Values: "
Write-Host "App Data		: 	$AppData"
Write-Host "Desktop			: 	$Desktop"
Write-Host "Documents		: 	$Documents"
Write-Host "Pictures		:	$Pictures"
Write-Host "Music			: 	$Music"
Write-Host "Videos			: 	$Videos"
# Confirm that the user would like to continue with the changes. Force the answer to be "Yes","Y","No", or "N"
$Confirmation = Read-Host "Continue with changes? (Y/N) "
While ("Y", "N", "Yes", "No" -notcontains $Confirmation) { 
	$Confirmation = Read-Host "Continue with changes? (Y/N) "
}
# If user does not wish to continue, quit the script
If ("N", "No" -contains $Confirmation) {
	Write-Host "Exiting script..."
	break
}
# Continue if user confirms
If ("Y", "Yes" -contains $Confirmation) {
	# Let the user know we are currently making changes to the registry
	Write-Host "Changing Registry. Please do not power off your machine, or log out of your profile. Please Wait..."
	# Make the necessary changes to the registry, depending on which options the user selected.
	if ("Y", "Yes" -contains $RoamAppData) { 
		Set-ItemProperty -Path $HKEY -Name "AppData" -Value "$AppData" 
	}
	if ("Y", "Yes" -contains $RoamDesktop) { 
		Set-ItemProperty -Path $HKEY -Name "Desktop" -Value "$Desktop" 
	}
	if ("Y", "Yes" -contains $RoamDocuments) { 
		Set-ItemProperty -Path $HKEY -Name "Personal" -Value "$Documents" 
		Set-ItemProperty -Path $HKEY -Name "My Pictures" -Value "$Pictures" 
		Set-ItemProperty -Path $HKEY -Name "My Music" -Value "$Music" 
		Set-ItemProperty -Path $HKEY -Name "My Videos" -Value "$Videos"
	}
	# Let the user know we are currently making changes to the registry
	Write-Host "Registry changed."
	# Get the latest registry values
	$AppData = (Get-ItemProperty -Path $HKEY).AppData
	$Desktop = (Get-ItemProperty -Path $HKEY).Desktop
	$Documents = (Get-ItemProperty -Path $HKEY).Personal
	$Pictures = (Get-ItemProperty -Path $HKEY)."My Pictures"
	$Music = (Get-ItemProperty -Path $HKEY)."My Music"
	$Videos = (Get-ItemProperty -Path $HKEY)."My Video"
	# Show the final values
	Write-Host "New values: "
	Write-Host "App Data		: 	$AppData"
	Write-Host "Desktop			: 	$Desktop"
	Write-Host "Documents		: 	$Documents"
	Write-Host "Pictures		:	$Pictures"
	Write-Host "Music			: 	$Music"
	Write-Host "Videos			: 	$Videos"
}