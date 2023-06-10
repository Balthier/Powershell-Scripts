# Script List

## Powershell

### Account Management
[Account Management\Compare-Compromised.ps1](Account%20Management/Compare-Compromised.ps1)  
Retrieves a list of emails from emails.txt, and compares them to breaches on "Have I Been Pwned"

[Account Management\Compare-CompromisedAD.ps1](Account%20Management/Compare-CompromisedAD.ps1)  
Connects to Active Directory to gather a list of E-Mail addresses, and compares them to breaches on "Have I Been Pwned"

[Account Management\New-Leaver.ps1](Account%20Management/New-Leaver.ps1)  
Processes a new Leaver by disabling AD accounts, and removing O365 licenses

[Account Management\New-Starter.ps1](Account%20Management/New-Starter.ps1)  
Processes a new Starter by creating an AD/O365 account, assigning a license, and sending a Welcome email


### Active Directory
[Active Directory\Get-ADMMembership.ps1](Active%20Directory/Get-ADMMembership.ps1)  
Retrieves a list of group membership for all ADM accounts, and outputs a list for each domain to a csv: ADM-Group-Membership-DOMAIN.csv

[Active Directory\Get-ADServer.ps1](Active%20Directory/Get-ADServer.ps1)  
Attempts to find all the servers ($Servers) in various known domains via AD, and DNS. Passwords need adding to lines 54-64.

[Active Directory\Get-ADUser-IllegalChar.ps1](Active%20Directory/Get-ADUser-IllegalChar.ps1)  
Retrieves a list of user accounts that have problematic characters included. E.g. Tab, New Lines, etc.

[Active Directory\Get-DCUpgradeStatus.ps1](Active%20Directory/Get-DCUpgradeStatus.ps1)  
Checks the DCs in the forest for some historical compatibility issues

[Active Directory\Get-GroupMemberOf.ps1](Active%20Directory/Get-GroupMemberOf.ps1)  
Retrieves a list of group membership for all groups in users OU, and outputs to csv: Group-MemberOf.csv

[Active Directory\Get-GroupMembership.ps1](Active%20Directory/Get-GroupMembership.ps1)  
Retrieves a list of group membership for all groups in users OU, in multiple domains, and outputs to csv: C:\temp\Group-Members-DOMAINSHORT.csv

[Active Directory\Get-SDHolderMembers.ps1](Active%20Directory/Get-SDHolderMembers.ps1)  
Retrieves a list of users that are a member of an SD Holder group, in all domains, and outputs to csv: SDHolderMembers.csv

[Active Directory\Get-VMAdmins.ps1](Active%20Directory/Get-VMAdmins.ps1)  
Retreives a list of users that are members of Administrators group in the Local Admin Servers/Workstations OUs, and outputs to csv: C:\temp\Computer-Admin-Group-Members-DOMAINSHORT.csv

[Active Directory\Get-WBInfo.ps1](Active%20Directory/Get-WBInfo.ps1)  
Retreives a backup policies from Windows Backup, on Domain Controllers

[Active Directory\Invoke-ADReplication.ps1](Active%20Directory/Invoke-ADReplication.ps1)  
Starts an AD replication in both directions, for all Domain Controllers in the Forest

[Active Directory\New-ADUGGroup.ps1](Active%20Directory/New-ADUGGroup.ps1)  
Takes information from NewUGGroups.csv, and creates new security groups with the specified users

[Active Directory\New-ADUser.ps1](Active%20Directory/New-ADUser.ps1)  
Takes informations from NewUsers.csv, and creates new user accounts, that are ready to be added to relevant group memberships

[Active Directory\Set-SMBv1.ps1](Active%20Directory/Set-SMBv1.ps1)  
Checks Domain Controllers for the SMBv1 Feature, and installs/enables the configuration


### AWS
[AWS\New-AWSInstance.ps1](AWS/New-AWSInstance.ps1)  
Launches a new AWS Instance **Incomplete**

[AWS\Update-AWSAccess.ps1](AWS/Update-AWSAccess.ps1)  
Automatically updates the specified IP of the security group in AWS


### Desktop
[Desktop\Get-PCInfo.ps1](Desktop/Get-PCInfo.ps1)  
Collects various information from the PC, and outputs to a CSV file.

[Desktop\Move-Redirects.ps1](Desktop/Move-Redirects.ps1)  
This script will redirect "My Documents", "AppData", and "Desktop" to $FR\USERNAME\FOLDER

[Desktop\Remove-TV.ps1](Desktop/Remove-TV.ps1)  
Removes the stored permanent password for Teamviewer 10

[Desktop\Start-Minimized.ps1](Desktop/Start-Minimized.ps1)  
A quick PowerShell script for starting program in a minimized state.


### DHCP
[DHCP\DHCP-Check.ps1](DHCP/DHCP-Check.ps1)  
Checks a specified IP Scope usages states


### DNS
[DNS\Check-DCDNS.ps1](DNS/Check-DCDNS.ps1)  
Checks DNS to ensure the Server/IP combination is correct

[DNS\Check-DNS.ps1](DNS/Check-DNS.ps1)  
Checks Google's DNS for the specified DNS name and waits until it appears

[DNS\Check-ServerIPinDNS.ps1](DNS/Check-ServerIPinDNS.ps1)  
Takes a server list in C:\Temp\Servers.txt, and checks each DHCP scope settings to see if the servers are set as DNS Servers, and outputs to csv: C:\Temp\DNS.csv


### Exchange
[Exchange\Clean-Database.ps1](Exchange/Clean-Database.ps1)  
Cleans up databases with disconnected mailboxes (Exchange 2007)

[Exchange\Get-AllEngineUpdates.ps1](Exchange/Get-AllEngineUpdates.ps1)  
Gets the latest Engine definition information currently on Exchange

[Exchange\Move-ExchangeDBs.ps1](Exchange/Move-ExchangeDBs.ps1)  
Migrates the active copy of all Exchange databases to/from the passive nodes

[Exchange\NewMailbox.ps1](Exchange/NewMailbox.ps1)  
Creates a new Mailbox on a specific DB based on department

[Exchange\Send-WelcomeEmail.ps1](Exchange/Send-WelcomeEmail.ps1)  
A quick PowerShell script for starting program in a minimized state.

[Exchange\Update-ExchangeServers.ps1](Exchange/Update-ExchangeServers.ps1)  
[UNFINISHED] Attempts to migrate databases to passive/active nodes, and install windows updates


### File Server
[File Server\Backup-CorruptFiles.ps1](File%20Server/Backup-CorruptFiles.ps1)  
Uses the file paths listed in CorruptFileRestore.txt, to copy the files from $SrcDrive to $DestDrive, while maintaining the folder structure

[File Server\Disable-DFSRConnections.ps1](File%20Server/Disable-DFSRConnections.ps1)  
Disables the DFS-R Connections on the specified server

[File Server\Enable-DFSRConnections.ps1](File%20Server/Enable-DFSRConnections.ps1)  
Enables the DFS-R Connections on the specified server

[File Server\Migrate-UserHomeDrives.ps1](File%20Server/Migrate-UserHomeDrives.ps1)  
Retrieves a list of folders in $SrcHome, and migrates them evenly across the destination folders in $NewHome. NOTE: Check the line comments for live/test actions.

[File Server\Restore-CorruptFiles.ps1](File%20Server/Restore-CorruptFiles.ps1)  
Uses the file paths listed in CorruptFileRestore.txt, to copy the files from $SrcDrive to $DestDrive, overwriting the existing files. Excludes files modified after $DestRestoreDate

[File Server\Update-FileServers.ps1](File%20Server/Update-FileServers.ps1)  
[UNFINISHED] This will bring down DFS-N/R on the servers from the text files, install windows updates, and bring DFS-R/N back up afterwards


### Folder Management
[Folder Management\Archive-Folder.ps1](Folder%20Management/Archive-Folder.ps1)  
(Re)Moves all files/folders in the subdirectories of a given folder.

[Folder Management\Archive-FolderEnhanced.ps1](Folder%20Management/Archive-FolderEnhanced.ps1)  
A quick PowerShell script for the backup of an entire directory, to another directory while stopping associated services

[Folder Management\Archive-WoTReplays.ps1](Folder%20Management/Archive-WoTReplays.ps1)  
Archives all World of Tank replays in to an Archive folder, except the most recent month

[Folder Management\Compare-FileLoss.ps1](Folder%20Management/Compare-FileLoss.ps1)  
Keeps a record of all filenames in the Paths, and detects if any have disappeared since the day before

[Folder Management\Convert-CSV.ps1](Folder%20Management/Convert-CSV.ps1)  
Converts a CSV file into XLS

[Folder Management\Move-CameraFiles.ps1](Folder%20Management/Move-CameraFiles.ps1)  
Organizes the Camera files in to Folders by date

[Folder Management\Set-Permissions.ps1](Folder%20Management/Set-Permissions.ps1)  
Removes Non-Inherited access, and grants full control/owner rights


### Hyper-V
[Hyper-V\Optimize-VHD.ps1](Hyper-V/Optimize-VHD.ps1)  
Mounts and Optimises VHD disks in Hyper-V to reduce disk size


### Server
[Server\Get-EncrpytionSettings.ps1](Server/Get-EncrpytionSettings.ps1)  
Checks what Kerberos Encryption ciphers are enabled on the server (Server 2016)

[Server\UpdateServer.ps1](Server/UpdateServer.ps1)  
This is a simple Powershell script to update a list of specified servers


### Set-ReadMe
[Set-ReadMe\Set-ReadMe.ps1](Set-ReadMe/Set-ReadMe.ps1)  
Re-Generates the README.md file with the latest information from all scripts


### TeamViewer
[TeamViewer\Connect-Teamviewer.ps1](TeamViewer/Connect-Teamviewer.ps1)  
Connect-Teamviewer.ps1 



### vCenter
[vCenter\Restart-Servers.ps1](vCenter/Restart-Servers.ps1)  
This is a simple Powershell script to restart a list of servers in a specific order/groupings

[vCenter\Restart-Service-Basic.ps1](vCenter/Restart-Service-Basic.ps1)  
Restarts the NLA Service on the servers contain in a .txt file

[vCenter\Restart-Service.ps1](vCenter/Restart-Service.ps1)  
Restarts the NLA Service on the servers contain in a .txt file - Contains basic error checking, and tracking of failed servers

