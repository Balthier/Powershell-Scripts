# Script List

## Powershell

### Account Management
[Account Management\Compare-Compromised.ps1](Powershell-Scripts/Account%20Management/Compare-Compromised.ps1)  
Retrieves a list of emails from emails.txt, and compares them to breaches on "Have I Been Pwned"

[Account Management\Compare-CompromisedAD.ps1](Powershell-Scripts/Account%20Management/Compare-CompromisedAD.ps1)  
Connects to Active Directory to gather a list of E-Mail addresses, and compares them to breaches on "Have I Been Pwned"

[Account Management\New-Leaver.ps1](Powershell-Scripts/Account%20Management/New-Leaver.ps1)  
Processes a new Leaver by disabling AD accounts, and removing O365 licenses

[Account Management\New-Starter.ps1](Powershell-Scripts/Account%20Management/New-Starter.ps1)  
Processes a new Starter by creating an AD/O365 account, assigning a license, and sending a Welcome email


### AWS
[AWS\New-AWSInstance.ps1](Powershell-Scripts/AWS/New-AWSInstance.ps1)  
Launches a new AWS Instance **Incomplete**

[AWS\Update-AWSAccess.ps1](Powershell-Scripts/AWS/Update-AWSAccess.ps1)  
Automatically updates the specified IP of the security group in AWS


### Desktop
[Desktop\Get-PCInfo.ps1](Powershell-Scripts/Desktop/Get-PCInfo.ps1)  
Collects various information from the PC, and outputs to a CSV file.

[Desktop\Move-Redirects.ps1](Powershell-Scripts/Desktop/Move-Redirects.ps1)  
This script will redirect "My Documents", "AppData", and "Desktop" to $FR\USERNAME\FOLDER

[Desktop\Remove-TV.ps1](Powershell-Scripts/Desktop/Remove-TV.ps1)  
Removes the stored permanent password for Teamviewer 10

[Desktop\Start-Minimized.ps1](Powershell-Scripts/Desktop/Start-Minimized.ps1)  
A quick PowerShell script for starting program in a minimized state.


### DNS
[DNS\Check-DNS.ps1](Powershell-Scripts/DNS/Check-DNS.ps1)  
Checks Google's DNS for the specified DNS name and waits until it appears


### Exchange
[Exchange\Clean-Database.ps1](Powershell-Scripts/Exchange/Clean-Database.ps1)  
Cleans up databases with disconnected mailboxes (Exchange 2007)

[Exchange\NewMailbox.ps1](Powershell-Scripts/Exchange/NewMailbox.ps1)  
Creates a new Mailbox on a specific DB based on department

[Exchange\Send-WelcomeEmail.ps1](Powershell-Scripts/Exchange/Send-WelcomeEmail.ps1)  
A quick PowerShell script for starting program in a minimized state.


### Folder Management
[Folder Management\Archive-Folder.ps1](Powershell-Scripts/Folder%20Management/Archive-Folder.ps1)  
(Re)Moves all files/folders in the subdirectories of a given folder.

[Folder Management\Archive-FolderEnhanced.ps1](Powershell-Scripts/Folder%20Management/Archive-FolderEnhanced.ps1)  
A quick PowerShell script for the backup of an entire directory, to another directory while stopping associated services

[Folder Management\Archive-WoTReplays.ps1](Powershell-Scripts/Folder%20Management/Archive-WoTReplays.ps1)  
Archives all World of Tank replays in to an Archive folder, except the most recent month

[Folder Management\Compare-FileLoss.ps1](Powershell-Scripts/Folder%20Management/Compare-FileLoss.ps1)  
Keeps a record of all filenames in the Paths, and detects if any have disappeared since the day before

[Folder Management\Convert-CSV.ps1](Powershell-Scripts/Folder%20Management/Convert-CSV.ps1)  
Converts a CSV file into XLS

[Folder Management\Move-CameraFiles.ps1](Powershell-Scripts/Folder%20Management/Move-CameraFiles.ps1)  
Organizes the Camera files in to Folders by date

[Folder Management\Set-Permissions.ps1](Powershell-Scripts/Folder%20Management/Set-Permissions.ps1)  
Removes Non-Inherited access, and grants full control/owner rights


### Hyper-V
[Hyper-V\Optimize-VHD.ps1](Powershell-Scripts/Hyper-V/Optimize-VHD.ps1)  
Mounts and Optimises VHD disks in Hyper-V to reduce disk size


### Set-ReadMe
[Set-ReadMe\Set-ReadMe.ps1](Powershell-Scripts/Set-ReadMe/Set-ReadMe.ps1)  
Re-Generates the README.md file with the latest information from all scripts


### TeamViewer
[TeamViewer\Connect-Teamviewer.ps1](Powershell-Scripts/TeamViewer/Connect-Teamviewer.ps1)  
Connect-Teamviewer.ps1 


