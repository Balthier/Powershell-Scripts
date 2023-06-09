<#
.Synopsis
Creates a new Mailbox on a specific DB based on department

.Notes
Author: Balthier Lionheart
#>

$shared = Read-Host "Shared? (Y/N)"
While ("Y", "N", "Yes", "No" -notcontains $shared) { 
	$shared = Read-Host "Shared? (Y/N) "
}
if ("Y", "Yes" -contains $shared) {
 $t = "SharedMB_DB" 
}

$EmailDomain = ""
$Domain = ""
$password = Read-Host "Enter password" -AsSecureString
$forename = Read-Host "Forename (a-Z Only)"
$surname = Read-Host "Surname (a-Z Only)"
$f = $forename.Trim()
$s = $surname.Trim()
$fn = $forename + " " + $surname
$a = $f + "." + $s
if (!$t) {
	$team = Read-Host "1) Accounts
2) Admin
3) International
4) Production
5) Research & Development
6) Sales
7) Tech Support
Department No."
	if ($team) {
		if ($team -eq 1) {
			$t = "Accounts_DB"
		}
		if ($team -eq 2) {
			$t = "Administration_DB"
		}
		if ($team -eq 3) {
			$t = "InternationalDB"
		}
		if ($team -eq 4) {
			$t = "Production_DB"
		}
		if ($team -eq 5) {
			$t = "R&D_DB"
		}
		if ($team -eq 6) {
			$t = "International_DB"
		}
		if ($team -eq 7) {
			$t = "TechSupport_DB"
		}
	}
}
$snapinAdded = Get-PSSnapin | Select-String "Microsoft.Exchange.Management.PowerShell.Admin"
if (!$snapinAdded) {
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
}
If ($shared -eq "Yes" -or $shared -eq "Y") {
	New-Mailbox -Alias "$a" -Name "$fn" -Database "$t" -OrganizationalUnit "$Domain/Users" -Shared -UserPrincipalName "$a@$EmailDomain"
}
else {
	New-Mailbox -Name "$fn" -Alias "$a" -OrganizationalUnit "$Domain/Users" -UserPrincipalName "$a@$EmailDomain" -SamAccountName "$a" -FirstName "$f" -Initials '' -LastName "$s" -Password $password -ResetPasswordOnNextLogon $true -Database "$t"
}