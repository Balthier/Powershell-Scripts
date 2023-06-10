<#
.Synopsis
Retrieves a list of group membership for all groups in users OU, and outputs to csv: Group-MemberOf.csv
#>


$OU = "OU=users,DC=domain,DC=com"
$Domain = "domain.com"
$Export = @()
$Groups = Get-ADGroup -Server $Domain -Filter * -SearchBase $OU
$Groups | Sort-Object | Select-Object -Unique | ForEach-Object {
    $Name = $_.name
    Write-Output "Getting MemberOf data for $Name"
    $Memberof = (Get-ADPrincipalGroupMembership -Identity $_).name | Out-String
    $ArrayAdd = New-Object PSObject
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Group" -Value $Name
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "MemberOf" -Value $MemberOf
    $Export += $ArrayAdd
}
$Export | Export-Csv Group-MemberOf.csv -NoTypeInformation
