<#
.Synopsis
Cleans up databases with disconnected mailboxes (Exchange 2007)

.Example
To Clean the databases
Clean-Database.ps1 -Clean
	
.Example
To list the disconnected mailboxes
Clean-Database.ps1 -list
	
.Example
To clean the databases and then list the disconnected mailboxes (Recommended)
Clean-Database.ps1 -Clean -list
	
.Notes
Author: Balthier Lionheart
#>

Param(
	[switch]$Clean,
	[switch]$list
)

$snapinAdded = Get-PSSnapin | Select-String "Microsoft.Exchange.Management.PowerShell.Admin"
if (!$snapinAdded) {
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
}


$DBList = Get-MailboxDatabase | Sort-Object

Foreach ($DB in $DBList) {
	$DBName = $DB.Name
	$DBServ = $DB.ServerName
	$DBStor = $DB.StorageGroupName
	$DBFull = "$DBServ\$DBStor\$DBName"
	If ($Clean) {
		Write-Host "Cleaning $DBName..."
		Clean-MailboxDatabase "$DBFull"
	}
	If ($list) {
		If ($ServList) {
			$ServList += $DBServ
		}
		Else {
			$ServList = @()
			$ServList += $DBServ
		}
		
	}
}

If ($list -and $ServList) {
	$ServList = $ServList | Select-Object -Uniq
	Foreach ($serv in $ServList) {
		if ($output) {
			$output += Get-MailboxStatistics -Server $serv | Where-Object { $_.DisconnectDate -ne $null } | Select-Object DisplayName, DisconnectDate
		}
		else {
			$output = @()
			$output = Get-MailboxStatistics -Server $serv | Where-Object { $_.DisconnectDate -ne $null } | Select-Object DisplayName, DisconnectDate
		}
	}
	Write-Host $output 
}