<#
.Synopsis
Connects to Active Directory to gather a list of E-Mail addresses, and compares them to breaches on "Have I Been Pwned"

.Notes
Author: Balthier Lionheart
#>

###############
## Includes ###
###############

. "..\Shared\AD-Functions.ps1"

#toggleLogging("On")

$defaults = getDefaults
$wLevel = $defaults[0]
$eLevel = $defaults[1]
$Creds = $defaults[5]
$ADServer = $defaults[6]
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$SiteRequest = "https://haveibeenpwned.com/api/v2/breaches"
$SiteResults = Invoke-WebRequest -uri $SiteRequest
$SiteResults = $SiteResults.Content | ConvertFrom-JSON -Type String
$s = 0
$SiteCount = $SiteResults.Count

While ($s -lt $SiteCount) {
	$SiteResults[$s].AddedDate = $SiteResults[$s].AddedDate.Replace("T", " ")
	$SiteResults[$s].AddedDate = $SiteResults[$s].AddedDate.Replace("Z", " ")
	$SiteResults[$s].ModifiedDate = $SiteResults[$s].ModifiedDate.Replace("T", " ")
	$SiteResults[$s].ModifiedDate = $SiteResults[$s].ModifiedDate.Replace("Z", " ")
	$SiteResults[$s].DataClasses = $SiteResults[$s].DataClasses -join '; '
	$s++
}

$SiteResults | Export-CSV ".\Breaches.csv" -NoTypeInformation

$session = connectAD $ADServer $Creds $eLevel $wLevel
$session = $session[1]

$accounts = Invoke-Command -Session $session -ScriptBlock { Get-ADUser -Filter 'enabled -eq $true' -Properties EmailAddress } -ErrorAction $eLevel
$accounts = $accounts | Sort-Object Name
$emails = $accounts.EmailAddress
$emails = $emails | Where-Object { $_ }
$emailsCount = $emails.count

$Date = Get-Date -format "dd-MM-yyyy"

$SleepTime = 2
$WaitMins = $emailsCount * 2 / 60
$WaitMins = [math]::Round($WaitMins)

$WaitTime = (get-date).AddMinutes($WaitMins).ToString("HH:mm")
Write-Host "`n"
Write-Host "Checking for compromised accounts... ETA $WaitMins minutes ($WaitTime)"
$i = 0
$results = @()
$Links = ""

While ($i -lt $emailsCount) {
	$Content = $Null
	$Result = $Null
	Write-Host "[$i]" $emails[$i]
	$email = $emails[$i]
	$request = "https://haveibeenpwned.com/api/v2/breachedaccount/" + $email + "?truncateResponse=true"
	try {
		$result = Invoke-WebRequest -uri $request
		$status = $result.StatusCode
	}
	catch {
		$status = $_.Exception.Response.StatusCode.Value__
	}
	Write-Host "Status:" $Status
	if ($status -eq 200) {
		$LinksFull = $result.Links
		$l = 0
		While ($l -lt $LinksFull.href.count) {
			$href = $LinksFull.href[$l]
			$href = $href.Replace('\"', '')
			$href = $href | Where-Object { $_ }
			If ($Links) {
				$Links = $Links + "; " + $href
			}
			Else {
				$Links = $href
			}
			$l++
		}
		$content = $result.Content.Replace('{"Name":"', '')
		$content = $content.Replace('[', '')
		$content = $content.Replace(']', '')
		$content = $content.Replace('"}', '')
		$contentArray = $content -Split ","
		$CompCount += $contentArray.count
		$results += New-Object -TypeName psobject -Property @{"Checked Date" = $Date; "E-Mail" = $email; "Breaches" = $Content; }
	}
	Start-Sleep $SleepTime
	$i++
}

if (Test-Path -Path ".\Breached-Accounts.csv") {
	$DupeCheck = Get-Content -Path ".\Breached-Accounts.csv" | Select-String $date | Select-String $email
	if (!$DupeCheck) {
		$results | Export-CSV ".\Breached-Accounts.csv" -Append -NoTypeInformation
	}
}
Else {
	$results | Export-CSV ".\Breached-Accounts.csv" -NoTypeInformation
}