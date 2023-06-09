<#
.Synopsis
(Re)Moves all files/folders in the subdirectories of a given folder.

.Notes
Author: Balthier Lionheart
Created: 2015-03-16
Modified: 2015-03-16
#>

# SET VARIABLES
[CmdletBinding()]
Param(
	[switch]$WhatIf
)

# Current Date
$Date = Get-Date
# Original file location, without trailing \
$OrigPath = "C:\Downloads"
# Backup folder location, without trailing \
$BackupPath = "C:\Backup"
# TEXT FILE CONTAINING A LIST OF FOLDERS TO BACKUP FROM
$FolderFile = "Folders.txt"
# FULL FILENAME FOR THE TEXT FILE
$SkipFile = "$OrigPath\$FolderFile"
# Define today's backup folder
$BackupDir = "{0}-{1:d2}-{2:d2}" -f $date.year, $date.month, $date.day
# Log folder location
$BackupErrorLogDir = "$BackupPath\logs"
# Define today's log file
$BackupErrorLogFile = "{0}-{1:d2}-{2:d2}.log" -f $date.year, $date.month, $date.day

# 
# BEGIN LOGGING PROCESS
# 

# Action to take on errors - "SilentyContinue": Continue and do not display errors
$ErrorActionPreference = "SilentlyContinue"

# Stop any previous logging
Stop-Transcript | out-null

# Action to take on errors - "Continue": Continue on error, display errors
$ErrorActionPreference = "Continue"

# Create log folder
New-Item $BackupErrorLogDir -Type Directory -Force
# Begin logging to log file
Start-Transcript -Path "$BackupErrorLogDir\$BackupErrorLogFile" -Append


# GET FOLDER LIST AND OUTPUT TO .TXT FILE
Get-ChildItem $OrigPath | Where-Object { $_.PSIsContainer } | ForEach-Object { $_.Name } > $SkipFile

# CREATE ARRAY WITH THE OUTPUT FROM THE FILE
$Skip = Get-Content $SkipFile

# RUN THROUGH EACH FOLDER AND PERFORM COMMANDS
$Skip | ForEach-Object {
	# SET THE FOLDER TO DELETE FROM
	$SkipFolder = $OrigPath + "\" + $_ + "\*"
	$BackupFolder = $BackupPath + "\" + $_
	New-Item $BackupFolder -type directory -Force -WhatIf:$WhatIf
	Move-Item $SkipFolder $BackupFolder -Verbose -WhatIf:$WhatIf
}

# 
# BEGIN CLEAN UP PROCESS
# 
# Stops logging process
Stop-Transcript 
# Remove the folder list
Remove-Item $SkipFile