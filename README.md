# Script List

## Powershell

### Account Management
[Account Management\Compare-Compromised.ps1](Account%20Management\Compare-Compromised.ps1)  
Retrieves a list of emails from emails.txt, and compares them to breaches on "Have I Been Pwned"

[Account Management\Compare-CompromisedAD.ps1](Account%20Management\Compare-CompromisedAD.ps1)  
Connects to Active Directory to gather a list of E-Mail addresses, and compares them to breaches on "Have I Been Pwned"

[Account Management\New-Leaver.ps1](Account%20Management\New-Leaver.ps1)  
Processes a new Leaver by disabling AD accounts, and removing O365 licenses

[Account Management\New-Starter.ps1](Account%20Management\New-Starter.ps1)  
Processes a new Starter by creating an AD/O365 account, assigning a license, and sending a Welcome email


### AWS
[AWS\New-AWSInstance.ps1](AWS\New-AWSInstance.ps1)  
Launches a new AWS Instance **Incomplete**


### Desktop
[Desktop\Get-PCInfo.ps1](Desktop\Get-PCInfo.ps1)  
Collects various information from the PC, and outputs to a CSV file.

[Desktop\Move-Redirects.ps1](Desktop\Move-Redirects.ps1)  
This script will redirect "My Documents", "AppData", and "Desktop" to $FR\USERNAME\FOLDER

[Desktop\Start-Minimized.ps1](Desktop\Start-Minimized.ps1)  
A quick PowerShell script for starting program in a minimized state.


### Exchange
[Exchange\Clean-Database.ps1](Exchange\Clean-Database.ps1)  
Cleans up databases with disconnected mailboxes (Exchange 2007)

[Exchange\NewMailbox.ps1](Exchange\NewMailbox.ps1)  
Creates a new Mailbox on a specific DB based on department

[Exchange\Send-WelcomeEmail.ps1](Exchange\Send-WelcomeEmail.ps1)  
A quick PowerShell script for starting program in a minimized state.


### Hyper-V
[Hyper-V\Optimize-VHD.ps1](Hyper-V\Optimize-VHD.ps1)  
Mounts and Optimises VHD disks in Hyper-V to reduce disk size


### Server
[Server\Archive-Folder.ps1](Server\Archive-Folder.ps1)  
A quick PowerShell script for the backup of an entire directory, to another directory


### Set-ReadMe
[Set-ReadMe\Set-ReadMe.ps1](Set-ReadMe\Set-ReadMe.ps1)  
Re-Generates the README.md file with the latest information from all scripts

