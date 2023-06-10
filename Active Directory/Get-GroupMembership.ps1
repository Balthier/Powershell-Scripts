<#
.Synopsis
Retrieves a list of group membership for all groups in users OU, in multiple domains, and outputs to csv: C:\temp\Group-Members-DOMAINSHORT.csv
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
        "ou=users,$ADDomain"
    )
    $Export = @()
    $Groups = @()
    $Groups += $OUs | ForEach-Object { Get-ADGroup -Server $Domain -Filter * -searchbase $_ }
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
                Write-Host "`nAn error occurred while trying to get the members of group $GroupName"
                Write-Host "Error: $_`n"
            }
            Foreach ($TempUser in $TempUsers) {
                $TempUser = $TempUser.DistinguishedName
                $TempSubDomain = ($TempUser.split(",") | Where-Object { $_ -like "*DC=*" })[0].replace("DC=", "")
                If ($TempSubDomain -eq "DOMAIN") {
                    $TempDomain = "DOMAIN.com"
                }
                Else {
                    $TempDomain = $TempSubDomain + ".DOMAIN.com"
                }
                Try {
                    $User = Get-ADUser -Identity $TempUser -Properties * -Server $TempDomain
                }
                Catch {
                    Write-Host "`nAn error occurred while getting the details for $TempUser in $TempDomain. Skipping.."
                    Write-Host "Error: $_`n"
                }
                #$Name = $User.Name
                #$SAMAccountName = $User.SAMAccountName
                $DistinguishedName = $User.DistinguishedName
                $managedObjects = $User.managedObjects | Out-String
                $Manager = $User.Manager
                $msRTCSIPUserRoutingGroupId = "$User.msRTCSIP-UserRoutingGroupId"
                $PrimaryGroup = $User.PrimaryGroup
                $primaryGroupID = $User.PrimaryGroupID
                $SamAccountName = $User.SamAccountName
                $samAccountType = $User.SamAccountType
                $UserPrincipalName = $User.UserPrincipalName
                $MemberOf = (($User | Select-Object -ExpandProperty MemberOf).split(",", 2) | Where-Object { $_ -like "CN=*" }).replace("CN=", "") | Sort-Object | Out-String
                $ArrayAdd = New-Object PSObject
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Group" -Value $GroupName
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value $DistinguishedName
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "ManagedObjects" -Value $managedObjects
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Manager" -Value $Manager
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "msRTCSIPUserRoutingGroupId" -Value $msRTCSIPUserRoutingGroupId
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "PrimaryGroup" -Value $PrimaryGroup
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "PrimaryGroupID" -Value $primaryGroupID
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "SamAccountName" -Value $SamAccountName
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "SamAccountType" -Value $SamAccountType
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "UserPrincipalName" -Value $UserPrincipalName
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "MemberOf" -Value $MemberOf
                #$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
                #$ArrayAdd | Add-Member -MemberType NoteProperty -Name "SAMAccountName" -Value $SAMAccountName
                #$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Domain" -Value $Domain
                #$ArrayAdd | Add-Member -MemberType NoteProperty -Name "Group" -Value $GroupName
                #$ArrayAdd | Add-Member -MemberType NoteProperty -Name "MemberOf" -Value $MemberOf
                $Export += $ArrayAdd
                $User = $NULL
                $TempUser = $NULL
				
            }
        }
        Write-Output "`nExporting CSV..."
        $Export | Export-Csv C:\temp\Group-Members-$DomainShort.csv -NoTypeInformation
    }
    Else {
        Write-Output "`nNo users found in the OUs specified"
    }
}

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`nTotal Runtime:"$Runtime"`n"