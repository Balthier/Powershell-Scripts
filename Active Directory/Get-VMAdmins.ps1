<#
.Synopsis
Retreives a list of users that are members of Administrators group in the Local Admin Servers/Workstations OUs, and outputs to csv: C:\temp\Computer-Admin-Group-Members-DOMAINSHORT.csv
#>


$StartTime = Get-Date
Write-Output "`nSetting variables..."
$Domains = @{
	"DOMAIN1.FQ.DN" = "DOMAIN-SHORT"
	"DOMAIN2.FQ.DN" = "DOMAIN-SHORT"
	"DOMAIN3.FQ.DN" = "DOMAIN-SHORT"
}

$Domains.GetEnumerator() | ForEach-Object {
	$Domain = $($_.Key)
	$DomainShort = $($_.Value)
	$DomainSplit = $Domain -Split "\."
	$Groups = @()
	$ADDomain = $NULL
	$Export = $NULL
	$Groups = $NULL
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
	$OUs = @(
		"OU=Local Admin Servers,OU=users,$ADDomain",
		"OU=Local Admin Workstations,OU=users,$ADDomain"
	)
	$Export = @()
	$Groups = @()
	$Groups += $OUs | ForEach-Object { Get-ADGroup -Server $Domain -Filter * -SearchBase $_ | Where-Object { $_.Name -Like "*_Administrators" } }
	If ($Groups) {
		$Groups = $Groups.Name
		$i = 0
		$Total = $Groups.Count
		$Groups | ForEach-Object {
			$i++
			Write-Host "`nGetting Group Membership for group: $_ [$i / $Total]"
			$GroupName = $_
			Try {
				$TempUsers = Get-ADGroupMember -Identity $_ -Server $Domain -Recursive
			}
			Catch {
				Write-Host "An error occurred while trying to get the members of group $GroupName"
				Write-Host "Error: $_"
			}
			Foreach ($TempUser in $TempUsers) {
				$TempUser = $TempUser.SamAccountName
				Try {
					$User = Get-ADUser -Identity $TempUser -Properties * -Server $Domain
				}
				Catch {
					Write-Host "An error occurred while getting the details for $TempUser in $Domain. Skipping.."
					Write-Host "Error: $_"
				}
				$Name = $User.Name
				$Ext4 = $User.extensionattribute4
				$ArrayAdd = New-Object PSObject
				$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
				$ArrayAdd | Add-Member -MemberType NoteProperty -Name "SAMAccountName" -Value $TempUser
				$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Domain" -Value $Domain
				$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Group" -Value $GroupName
				$ArrayAdd | Add-Member -MemberType NoteProperty -Name "ExtensionAttribute4" -Value $Ext4
				$Export += $ArrayAdd
				$User = $NULL
				$TempUser = $NULL
				
			}
		}
		Write-Output "`nExporting CSV..."
		$Export | Export-Csv C:\temp\Computer-Admin-Group-Members-$DomainShort.csv -NoTypeInformation
	}
	Else {
		Write-Output "`nNo users found in the OUs specified"
	}
}

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`nTotal Runtime:"$Runtime"`n"												