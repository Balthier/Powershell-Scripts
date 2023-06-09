<#
.Synopsis
Archives all World of Tank replays in to an Archive folder, except the most recent month
#>

$BaseFolder = "D:\World of Tanks\replays"
$BackupFolder = "$BaseFolder\Archive"
$FileList = Get-ChildItem -File $BaseFolder | Where-Object FullName -NotLike "*last_battle*"


ForEach ($File in $FileList) {
	$Filepath = $File.FullName
	$Created = Get-Date ($File.CreationTime) -Format "yyyy-MM"
	$Month = Get-Date -Format "yyyy-MM"
	if ($Created -ne $Month) {
		$DestFolder = "$BackupFolder\$Created"
		$DestFolderCheck = Test-Path $DestFolder
		If (!$DestFolderCheck) {
			New-Item -ItemType Directory -Force $DestFolder -Verbose 
  }
		Move-Item -Path $FilePath -Destination $DestFolder -Verbose
	}
}