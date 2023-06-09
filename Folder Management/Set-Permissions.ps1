<#
.Synopsis
Removes Non-Inherited access, and grants full control/owner rights
#>

$count = 0
$dir = ""
$right = "FullControl"
$principal = ""
$owner = ""
$search = ""
$ownerPrincipal = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $owner
$retain = New-Object System.Security.AccessControl.FileSystemAccessRule($owner, $Right, "Allow")
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Principal, $Right, "Allow")
$customers = Get-ChildItem -Path "$Dir" -Directory
ForEach ($folder in $customers) {
	$customer = $folder.name
	$custDir = "$dir\$customer"
	$subDir = Get-ChildItem -Path "$custDir" -Directory
	ForEach ($folder in $subDir) {
		$folderName = $folder.name
		If ($folderName -like "*$search*") {
			$count++
			$fullpath = "$dir\$customer\$folderName"
			Write-Host "[$count] $fullpath"
			$acl = get-acl $fullpath
			$acl.SetAccessRuleProtection($True, $False)
			Foreach ($access in $acl.access) {
				if ($access.isinherited -eq $false) {
					$acl.RemoveAccessRule($access)
				}
			}
			$acl.SetAccessRule($retain)
			$acl.SetAccessRule($rule)
			$acl.SetOwner($ownerPrincipal)
			set-acl $fullpath $acl
		}
	}
}
