<#
.Synopsis
Automatically updates the specified IP of the security group in AWS
#>

$AccessKey = ""
$SecretKey = ""
$IPLookupURL = "ipv4bot.whatismyipaddress.com"
$NewIP = (Invoke-RestMethod -Uri $IPLookupURL -Method GET) + "/32"
$Region = ""
$SecGroupID = ""

Try {
	$SG = Get-EC2SecurityGroup -GroupID $SecGroupID -Region $Region -AccessKey $AccessKey -SecretKey $SecretKey
}
Catch {
	Write-Error "`nAn Error Occurred while retrieving the default information: $_"
	Exit
}
$OldPermissions = $SG.IpPermissions
$OldIP = $OldPermissions.Ipv4Ranges.CidrIp
$Permissions = $SG.IpPermissions
$NewPermissions = New-Object Amazon.EC2.Model.IpPermission 
$NewPermissions.IpProtocol = $Permissions.IpProtocol
$NewPermissions.FromPort = $Permissions.FromPort 
$NewPermissions.ToPort = $Permissions.ToPort 
$NewPermissions.IpRanges = $NewIP
If ($NewIP -ne $OldIP) {
	Write-Host "Old IP: $OldIP"
	Write-Host "New IP: $NewIP"
	Write-Host "IP change detected. Updating Security Group"
	Revoke-EC2SecurityGroupIngress -GroupId $SecGroupID -IpPermissions $OldPermissions -Region $Region -AccessKey $AccessKey -SecretKey $SecretKey
	Grant-EC2SecurityGroupIngress -GroupId $SecGroupID -IpPermissions $NewPermissions -Region $Region -AccessKey $AccessKey -SecretKey $SecretKey
}
Else {
	Write-Host "Old IP: $OldIP"
	Write-Host "Current IP: $NewIP"
	Write-Host "IP matches Security Group. Skipping."
}