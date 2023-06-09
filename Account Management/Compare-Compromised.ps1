<#
.Synopsis
Retrieves a list of emails from emails.txt, and compares them to breaches on "Have I Been Pwned"

.Notes
Author: Balthier Lionheart
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$emails = Get-Content -Path ".\emails.txt"
$emails = $emails | Where-Object { $_ }
$Date = Get-Date -format "dd-MM-yyyy"

$WaitMins = 2
$SleepTime = 2
$WaitTime = (get-date).AddMinutes($WaitMins).ToString("HH:mm")
Write-Host "`n"
Write-Host "Checking for compromised accounts... ETA $WaitMins minutes ($WaitTime)"
$i = 0
$results = @()
$Links = ""
$emailsCount = $emails.count
While ($i -lt $emailsCount) {
	$Content = $Null
	$Result = $Null
	Write-Host "[$i]" $emails[$i]
	$email = $emails[$i]
	$request = "https://haveibeenpwned.com/api/v2/breachedaccount/" + $email + "?truncateResponse=true"
	$ProgressPreference = "SilentlyContinue"
	try {
		$result = Invoke-WebRequest -uri $request
		$status = $result.StatusCode
	}
	catch {
		$status = $_.Exception.Response.StatusCode.Value__
	}
	Write-Host $Status
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
		$content = $content.Replace(',', ', ')
		$CompCount = $contentArray.count
		$results += New-Object -TypeName psobject -Property @{"Checked Date" = $Date; "E-Mail" = $email; "Breaches" = $Content; "Possible Breach Count" = $CompCount }
	}
	Start-Sleep $SleepTime
	$i++
}
if (Test-Path -Path ".\results.csv") {
	$DupeCheck = Get-Content -Path ".\results.csv" | Select-String $date | Select-String $email
	if (!$DupeCheck) {
		$results | Export-CSV ".\results.csv" -Append -NoTypeInformation
	}
}
Else {
	$results | Export-CSV ".\results.csv" -NoTypeInformation
}