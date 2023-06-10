<#
.Synopsis
Retrieves a list of group membership for all ADM accounts, and outputs a list for each domain to a csv: ADM-Group-Membership-DOMAIN.csv
#>


$StartTime = Get-Date

$Domains = @{
	"DOMAIN1.FQ.DN" = "DOMAIN-SHORT"
	"DOMAIN2.FQ.DN" = "DOMAIN-SHORT"
	"DOMAIN3.FQ.DN" = "DOMAIN-SHORT"
}

$Domains.GetEnumerator() | ForEach-Object {
	$Domain = $($_.Key)
	#$DomainShort = $($_.Value)
	$DomainSplit = $Domain -Split "\."
	#$Groups = @()
	$ADMUsers = $NULL
	$ADDomain = $NULL
	$Export = $NULL
	$Group = $NULL
	$TempGroups = $NULL
	$i = 0
	While ($i -lt $DomainSplit.Count) {
		If ($i -eq 0) {
			$ADDomain = $ADDomain + "DC=" + $DomainSplit[$i]
		}
		Else {
			$ADDomain = $ADDomain + ",DC=" + $DomainSplit[$i]
		}
		$i++
	}
	Write-Output "`nRetrieving list of users in $Domain..."
	$Export = @()
	$ADMUsers = Get-ADUser -Filter * -Server $Domain | Where-Object { $_.Name -Like "ADM*" }
	If ($ADMUsers) {
		$ADMUsers = $ADMUsers
		$i = 0
		$Total = $ADMUsers.Count
		$ADMUsers | ForEach-Object {
			$i++
			$SAMAccountName = $_.SamAccountName
			$Name = $_.Name
			Write-Host "`nGetting Group Membership for account: $SAMAccountName [$i / $Total]"
			$TempGroups = Get-ADPrincipalGroupMembership -Identity $SAMAccountName -Server $Domain
			If ($TempGroups) {
				Foreach ($TempGroup in $TempGroups) {
					$Group = $TempGroup.Name
					Write-Host "`nAdding $Group for account $_.SamAccountName"
					$ArrayAdd = New-Object PSObject
					$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
					$ArrayAdd | Add-Member -MemberType NoteProperty -Name "SAMAccountName" -Value $SAMAccountName
					$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Domain" -Value $Domain
					$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Location" -Value $_
					$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Group" -Value $Group
					$Export += $ArrayAdd
				}
			}
			Else {
				Write-Host "`n$_ is a member of no groups"
			}
		}
		Write-Output "`nExporting CSV..."
		$Export | Export-Csv ADM-Group-Membership-$Domain.csv -NoTypeInformation
	}
}

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`nTotal Runtime:"$Runtime"`n"	