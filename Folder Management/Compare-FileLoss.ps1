<#
.Synopsis
Keeps a record of all filenames in the Paths, and detects if any have disappeared since the day before
#>

$Paths = @(
    "D:\",
    "E:\"
)
$LogPath = "Logs"
$DateToday = Get-Date -Format "yyyy-MM-dd"
$DateYesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$LogNameToday = "$DateToday.txt"
$LogNameYesterday = "$DateYesterday.txt"
$LogNameMissing = "$DateToday - Missing.txt"
$LogFileToday = "$LogPath\$LogNameToday"
$LogFileYesterday = "$LogPath\$LogNameYesterday"
$LogFileMissing = "$LogPath\$LogNameMissing"
$LogFileYesterdayCheck = Test-Path $LogFileYesterday

ForEach ($FullPath in $Paths) {
    $PathCheck = Test-Path $FullPath
    If ($PathCheck) {
        $FileList = Get-ChildItem -Path $FullPath -Recurse | Select-Object FullName
        $FileList.FullName | Out-File -Append -FilePath $LogFileToday -NoClobber
    }
}

If (!$LogFileYesterdayCheck) {
    Break
}
Else {
    $LogYesterday = Get-Content $LogFileYesterday
    $LogToday = Get-Content $LogFileToday
    $FileLossCheck = Compare-Object -ReferenceObject $LogYesterday -DifferenceObject $LogToday
    If ($FileLossCheck) {
        Foreach ($File in $FileLossCheck) {
            If ($File.SideIndicator -eq "<=") {
                $File.InputObject | Out-File -Append -FilePath $LogFileMissing -NoClobber
            }
        }
    }
}