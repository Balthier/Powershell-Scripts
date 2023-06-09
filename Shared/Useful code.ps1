# GET WINDOWS VERSION
$windowsVersion = Get-WmiObject win32_operatingSystem | Select-Object caption

# GET $program VERSION
$programVersion = Get-WmiObject win32_product -filter "name like '%$program%'"

# GET POWERSHELL VERSION AND RUN APPROPRIATE COMMANDS
$psVersion = Get-Host | Select-Object version
if ($psVersion -Like "*2*") {
    Commands Here
}
if ($psVersion -Like "*1*") {
    Commands Here
}

# INSTALL WINDOWS SERVER BACKUP
Import-Module ServerManager
Add-WindowsFeature -Name Windows-Server-Backup -IncludeAllSubFeature
Add-WindowsFeature -Name Backup-Features -IncludeAllSubFeature

# GET ALL DISCONNECTED MAILBOXES
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
Get-MailboxStatistics | Where-Object { $_.DisconnectDate -ne $Null } | Format-Table displayname, database, disconnectdate

# NEW SHARED MAILBOX
New-Mailbox -Alias "" -Name "" -Database "" -Org "" -Shared -UserPrincipalName ""

# ADD FULL ACCESS TO MAILBOX
Add-MailboxPermission -Identity '' -User '' -AccessRights 'FullAccess'

Get-MailboxStatistics -Server | Where-Object { $_.DisconnectDate -ne $null } | Select-Object DisplayName, DisconnectDate

# Forwarding Address
Set-Mailbox -Identity  -ForwardingAddress  -DeliverToMailboxAndForward $true

# Add Rservered IP
netsh Dhcp Server \\192.168.1.1 Scope 192.168.254.0 Add reservedip 192.168.254.154 0CC47A00ED38 "" "" "BOTH"

# RE-ENABLE DISCONNECTED MAILBOX
Enable-Mailbox -Identity '' -Alias '' -Database ''

# CREATE A NEW MAILBOX
New-Mailbox -Name '' -Alias '' -OrganizationalUnit '' -UserPrincipalName '' -SamAccountName '' -FirstName '' -Initials '' -LastName '' -Password 'System.Security.SecureString' -ResetPasswordOnNextLogon $true -Database ''

# FIND START/END DAY OF MONTH
$CurrentDate = Get-Date -Format "yyyy/MM/dd"
$MonthStart = Get-Date $CurrentDate -Day 1
$MonthEnd = Get-Date $MonthStart.AddMonths(1).AddDays(-1)
$MonthStart = Get-Date $MonthStart -Format "yyyy/MM/dd"
$MonthEnd = Get-Date $MonthEnd -Format "yyyy/MM/dd"

Write-Output "$MonthStart - $MonthEnd"

# IMPORT SSL CERTIFICATE
Import-ExchangeCertificate -Path C:\Downloads\com.cer | Enable-ExchangeCertificate -Services "SMTP, IMAP, POP, IIS"

# PURGE SPECIFIC MASS EMAIL
$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking
New-ComplianceSearchAction -SearchName "" -Purge -PurgeType SoftDelete

New-ComplianceSearch -Name "" -ExchangeLocation All -ContentMatchQuery '""'

# HIDE FROM GAB HYBRID OFFICE 365
Get-ADUser -Filter { (enabled -eq "false") -and (msExchHideFromAddressLists -notlike "*") } -SearchBase "OU=,DC=,DC=" -Properties msExchHideFromAddressLists | Set-ADUser -Add @{msExchHideFromAddressLists = "TRUE" }

# ADD EMAIL FORWARD TO ANOTHER Address
$credentials = Get-Credential
Write-Output "Getting the Exchange Online cmdlets"
    
$Session = New-PSSession -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
    -ConfigurationName Microsoft.Exchange -Credential $credentials `
    -Authentication Basic -AllowRedirection
Import-PSSession $Session
Set-Mailbox -Identity "" -DeliverToMailboxAndForward $true -ForwardingSMTPAddress ""

# FIND ALL EMAIL FORWARDS GOING EXTERNALLY
$credentials = Get-Credential
Write-Output "Getting the Exchange Online cmdlets"
    
$Session = New-PSSession -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
    -ConfigurationName Microsoft.Exchange -Credential $credentials `
    -Authentication Basic -AllowRedirection
Import-PSSession $Session
 
$mailboxes = Get-Mailbox -ResultSize Unlimited
$domains = Get-AcceptedDomain
  
foreach ($mailbox in $mailboxes) {
  
    $forwardingSMTPAddress = $null
    Write-Host "Checking forwarding for $($mailbox.displayname) - $($mailbox.primarysmtpaddress)"
    $forwardingSMTPAddress = $mailbox.forwardingsmtpaddress
    $externalRecipient = $null
    if ($forwardingSMTPAddress) {
        $email = ($forwardingSMTPAddress -split "SMTP:")[1]
        $domain = ($email -split "@")[1]
        if ($domains.DomainName -notcontains $domain) {
            $externalRecipient = $email
        }
  
        if ($externalRecipient) {
            Write-Host "$($mailbox.displayname) - $($mailbox.primarysmtpaddress) forwards to $externalRecipient" -ForegroundColor Yellow
  
            $forwardHash = $null
            $forwardHash = [ordered]@{
                PrimarySmtpAddress = $mailbox.PrimarySmtpAddress
                DisplayName        = $mailbox.DisplayName
                ExternalRecipient  = $externalRecipient
            }
            $ruleObject = New-Object PSObject -Property $forwardHash
            $ruleObject | Export-Csv C:\temp\ExternalForward.csv -NoTypeInformation -Append
        }
    }
}

# ZENDESK TICKETS TESTING
Function searchZendeskUserTickets($email, $subdomain) {
    $params = connectZendesk
    $params = @{
        Uri     = "https://$subdomain.zendesk.com/api/v2/search.json?query=status<closed%20assignee:$email"
        Method  = 'Get'
        Headers = $params.Headers
    }
    $webreq = Invoke-RestMethod -Uri $params.Uri -Method $params.Method -Headers $params.Headers
    $results = $webreq.results# | Select-Object id,url,subject,status
    Return $results
}
Function connectZendesk() {
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    $Username = ""
    $Token = ""
	
    $params = @{
        Headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Username):$($Token)"))
        }
    }
    Return $params
}

$subdomain = ""
$email = ""
$allTickets = searchZendeskUserTickets $email $subdomain
$openTickets = $allTickets | Where-Object { $_.status -eq "open" }
$solvedTickets = $allTickets | Where-Object { $_.status -eq "solved" }

# ZENDESK USER CREATION TESTING
$email = ""
$subdomain = ""
$totalLicenses = "80"
$zendeskUsage = getZendeskUsage $subdomain
	
if ($zendeskUsage -lt $totalLicenses) {
    Write-Host "Licenses Used: $zendeskUsage/$totalLicenses"
    Write-Host "Creating Zendesk Agent..."
    $role = "agent"
    $result = createZendeskAccount $name $email $role $subdomain
}
else {
    Write-Host "Licenses Used: $zendeskUsage/$totalLicenses"
    Write-Host "No licenses available for Agent creation..."
    Write-Host "Creating End-User account instead..."
    $role = "end-user"
    $result = createZendeskAccount $name $email $role $subdomain
    $id = $result.user.id
    Write-Host "Account Created: https://$subdomain.zendesk.com/agent/users/$id"        
}

$ZendeskID = ""
$subdomain = ""

suspendZendeskUser $subdomain $ZendeskID

