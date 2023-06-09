# Find the current location of the script
$scriptPath = Split-Path -Parent $PSCommandPath
Set-Location $scriptPath

# Include the functions
. "..\Shared\Teamviewer-Functions.ps1"

# Set custom colour scheme
# setColourScheme

$TVAPI = ""
$email = ""

Function checkTeamviewer($TVAPI) {
	PingAPI $TVAPI
}

Function searchTVUser($TVAPI, $email) {
	$APIStatus = checkTeamviewer $TVAPI
	if ($APIStatus) {
		$User = GetAllUsersAPI $TVAPI $email
		Return $User
	}
}

Function deactivateTVUser($TVAPI, $email, $UserID) {
	$APIStatus = checkTeamviewer $TVAPI
	if ($APIStatus) {
		DeactivateUser $TVAPI $UserID $email
	}
}

Write-Host "`n"
Write-Host "Searching for Teamviewer Account..."
$TVmatch = searchTVUser $TVAPI $email
$UserID = $TVmatch.id
if ($TVmatch) {
	Write-Host "`n"
	Write-Host "Teamviewer: Yes" -ForegroundColor "Cyan"
}
else {
	Write-Host "Teamviewer: No" -ForegroundColor "Red"
}
if ($TVmatch) {
	Write-Host "`n"
	Write-Host "Disabling Teamviewer account..."
	deactivateTVUser $TVAPI $email $UserID
}