<#
.Synopsis
A quick PowerShell script for starting program in a minimized state.

.Notes
Author: Balthier Lionheart
#>


# Set the Server to send the email
$SMTPClient = New-Object Net.Mail.SmtpClient("SERVER") 
# Get all accounts created within the last hour
$mailboxes = Get-Mailbox | Where-Object { $_.WhenCreated -ge ((Get-Date).AddDays(-1)) }
# Set Email address to send from
$from = ""
# Set Email Subject
$subject = ""

# Check if the Exchange Powershell commands are loaded
$snapinAdded = Get-PSSnapin | Select-String "Microsoft.Exchange.Management.PowerShell.Admin"
if (!$snapinAdded) {
	# If not, load the required module (Exchange 2007)
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
}

# Run through each mailbox in the result
ForEach ($mailbox in $mailboxes ) {
	# Set the recipient email address
	$to = $mailbox.PrimarySMTPAddress
	# Set Message Body text
	$body = ""
	# Send the email
	$SMTPClient.Send($from, $to, $subject, $body)
}