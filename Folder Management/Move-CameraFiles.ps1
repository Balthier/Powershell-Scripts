<#
.Synopsis
Organizes the Camera files in to Folders by date
#>

$FTPFolder = "E:\FTP Server"
$Camera1 = "Camera-01 Front Garden"
$Camera2 = "Camera-02 Back Garden"

$files = Get-ChildItem -Path "$FTPFolder\$Camera1" -File

ForEach ($file in $files) {
    $item = $file.Name
    $date = $item.replace('ARC', '')
    $date = $date.replace('.jpg', '')
    $date = $date.replace('.mp4', '')
    $date = $date -replace ".{6}$"
    $FolderCheck = "Test-Path -Path $FTPFolder\$Camera1\$date"
    If (!$FolderCheck) {
        New-Item -Path "$FTPFolder\$Camera1" -Name "$date" -ItemType "directory" -Verbose
    }
    Move-Item -Path "$FTPFolder\$Camera1\$item" -Destination "$FTPFolder\$Camera1\$date\$item" -Verbose
}

$files = Get-ChildItem -Path "$FTPFolder\$Camera2" -File

ForEach ($file in $files) {
    $item = $file.Name
    $date = $item.replace('ARC', '')
    $date = $date.replace('.jpg', '')
    $date = $date.replace('.mp4', '')
    $date = $date -replace ".{6}$"
    $FolderCheck = "Test-Path -Path $FTPFolder\$Camera2\$date"
    If (!$FolderCheck) {
        New-Item -Path "$FTPFolder\$Camera2" -Name "$date" -ItemType "directory" -Verbose
    }
    Move-Item -Path "$FTPFolder\$Camera2\$item" -Destination "$FTPFolder\$Camera2\$date\$item" -Verbose
}