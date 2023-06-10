<#
.Synopsis
Uses the file paths listed in CorruptFileRestore.txt, to copy the files from $SrcDrive to $DestDrive, overwriting the existing files. Excludes files modified after $DestRestoreDate
#>


# VARIABLES
$StartTime = Get-Date
$LogTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$LogFile = "RestoreLog-$LogTime.log"
$DataFile = "CorruptFileRestore.txt"
$SrcDrive = "E:"
$DestDrive = "F:"
$PathCheck = $null
$SrcExistCheck = $null
$DestRestoreDate = Get-Date 13/08/2022
$DestModCheck = $null

Try {
    Start-Transcript -Path $LogFile -Append -NoClobber -IncludeInvocationHeader
}
Catch {
    Stop-Transcript
    Try {
        Start-Transcript -Path $LogFile -Append -NoClobber -IncludeInvocationHeader
    }
    Catch {
        throw "`n[$(Get-Date -DisplayHint Time)] Error creating log file. Exiting."
        
    }
}

$PathCheck = Test-Path "$DataFile"
If ($PathCheck) {
    Write-Output "`n[$(Get-Date -DisplayHint Time)] Retrieving file list..."
    $FileList = Get-Content "$DataFile" -ErrorAction Stop
}
Else {
    Write-Error "`n[$(Get-Date -DisplayHint Time)] Error loading $DataFile. Exiting.`n"
    Stop-Transcript
    Break
}

ForEach ($File in $FileList) {
    Write-Host "`n[$(Get-Date -DisplayHint Time)] Working with file: $File"
    $Source = $SrcDrive + $File
    $Destination = $DestDrive + $File
    $SrcExistCheck = Test-Path $Source
    If ($SrcExistCheck) {
        Write-Host "[$(Get-Date -DisplayHint Time)] Source file exists"
        $DestParentDir = ([System.IO.DirectoryInfo]$Destination).Parent.FullName
        $DestFolderCheck = Test-Path $DestParentDir
        If (!$DestFolderCheck) {
            Write-Host "[$(Get-Date -DisplayHint Time)] Parent folder $DestParentDir does not exist. Manually creating"
            New-Item $DestParentDir -ItemType Directory -WhatIf
        }
        $DestExistCheck = Test-Path $Destination
        If ($DestExistCheck) {
            $DestModCheck = (Get-Item "$Destination" -Force).LastWriteTime
            Write-Host "[$(Get-Date -DisplayHint Time)] Destination file exists. Getting last modified time"
        }
        Else {
            $DestModCheck = Get-Date $DestRestoreDate.AddDays(-1)
            Write-Host "[$(Get-Date -DisplayHint Time)] Destination file does not exist. Setting last modified time variable manually"
        }
        $DestModDate = Get-Date $DestModCheck -Format "dd/MM/yyyy"
        $DestRestDate = Get-Date $DestRestoreDate -Format "dd/MM/yyyy"
        If ($DestModCheck -gt $DestRestoreDate) {
            Write-Host "[$(Get-Date -DisplayHint Time)] Destination File modified after 13/08/2022 - Skipping"
        }
        else {
            Write-Host "[$(Get-Date -DisplayHint Time)] $DestModDate is not past $DestRestDate - Overwriting destination file"
            Copy-Item -Path $Source -Destination $Destination -Force -Verbose -WhatIf
        }
    }
    else {
        Write-Host "[$(Get-Date -DisplayHint Time)] Source File does not exist - Skipping"
    }
}

$EndTime = Get-Date
$Runtime = $EndTime - $StartTime
Write-Host "`n[$(Get-Date -DisplayHint Time)] Total Runtime: $Runtime"
Stop-Transcript