<#
.Synopsis
This is a simple Powershell script to restart a list of servers in a specific order/groupings

.Description
This script will only work with VMs that are contained within VCENTER1 or another linked VM Host. It will not work with Physical machines, or VMs that are not within the aforementioned infrastructure.

.Notes
Version: 2.5.0

.Parameter CSVFile
The full file path to the CSV file containing the list of Servers and restart order

.Parameter LogPath
The full file path to the location of the log folder, without the trailing slash. The log file itself, will be generated in this folder, using the format: "$LogPath\ServerRestart $Environment - $DateToday.log"

.Parameter Environment
This is the name of the respective environment. Will be used in the generation of the log file name

.Parameter WaitTime
This is the amount of time, in seconds, the script will wait before it restarts the next group of servers. Default 120

.Parameter SpecialWaitTime
This is the amount of time, in seconds, the script will wait before it restarts the next group of servers, if the current group contains "*wildcard1*" or "*wildcard2*". Default 240

.Parameter VDI
This is the target VDI server, where the VMs are currently configured. Default VCENTER1

.Example
./Restart-Servers.ps1 -CSVFile "C:\Temp\ServerList.csv" -LogPath "C:\Temp\Logs" -Environment "TEST"

"ServerList.csv" Contents:
server,group
ExampleServer1,1
ExampleServer2,2
ExampleServer3,2
ExampleServer4,3
ExampleServer5,3
ExampleServer6,4

This example would restart the servers (C:\Temp\ServerList.csv) in 4 separate groups, using the default wait period of 120 seconds, in between each server group. No ADE/WSV servers are present in the list, and so the SpecialWaitTime (default 240 seconds) does not apply. Progress and errors are wrote to the log file (C:\Temp\Logs\ServerRestart TEST - 2023-01-01.log)

.Example
./Restart-Servers.ps1 -CSVFile "C:\Temp\ServerList.csv" -LogPath "C:\Temp\Logs" -Environment "TEST" -WaitTime 60 -SpecialWaitTime 300

"ServerList.csv" Contents:
server,group
ExampleServer1,1
ExampleServer2,1
ExampleServer3,2
ExampleADEServer1,2
ExampleWSVServer1,2
ExampleServer4,3

This example would restart the servers (C:\Temp\ServerList.csv) in 3 separate groups, with a wait period of 60 seconds between groups 1 & 2, but 300 seconds between 2 & 3, and 60 seconds after group 3. Progress and errors are wrote to the log file (C:\Temp\Logs\ServerRestart TEST - 2023-01-01.log)

#>
Param(
    [Parameter(Mandatory = $true)][string[]]$CSVFile,
    [Parameter(Mandatory = $true)][string[]]$LogPath,
    [Parameter(Mandatory = $true)][string[]]$Environment,
    [Parameter(Mandatory = $false)][string[]]$VDI = "VCENTER1",
    [Parameter(Mandatory = $false)][string[]]$WaitTime = 120,
    [Parameter(Mandatory = $false)][string[]]$SpecialWaitTime = 240
)
Import-Module VMware.PowerCLI
$DateToday = Get-Date -Format "yyyy-MM-dd"
$LogFile = "$LogPath\ServerRestart $Environment - $DateToday.log"
Try {
    Start-Transcript -Path $LogFile -Append -NoClobber -IncludeInvocationHeader
}
Catch {
    Stop-Transcript
    Try {
        Start-Transcript -Path $LogFile -Append -NoClobber -IncludeInvocationHeader
    }
    Catch {
        Write-Error "`n[$(Get-Date -DisplayHint Time)] Error creating log file. Exiting."
        exit 3
    }
}

$StartTime = Get-Date
Write-Output "`n[$(Get-Date -DisplayHint Time)] Setting variables..."

$PathCheck = Test-Path "$CSVFile"
If ($PathCheck) {
    Write-Output "`n[$(Get-Date -DisplayHint Time)] Retrieving VMs to restart from file $CSVFile..."
    $ServerList = Import-Csv "$CSVFile" -ErrorAction Stop
}
Else {
    Write-Error "`n[$(Get-Date -DisplayHint Time)] Error loading $CSVFile. Exiting.`n"
    Stop-Transcript
    exit 4
}

Write-Output "`n[$(Get-Date -DisplayHint Time)] Configuring PowerCLI..."
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -DefaultVIServerMode Multiple -Confirm:$False | Out-Null

Write-Output "`n[$(Get-Date -DisplayHint Time)] Connecting to VM Hosts..."
Try {
    Connect-VIServer -Server $VDI -AllLinked:$True -ErrorAction Stop | Out-Null
}
Catch {
    Write-Error "`n[$(Get-Date -DisplayHint Time)] Login Failed."
    Stop-Transcript
    exit 5
}

Write-Output "`n[$(Get-Date -DisplayHint Time)] Attempting to restart VMs..."
$Count = 0
$Stage1 = $ServerList | Where-Object { $_.Server -like "*wildcard1*" }
If ($Stage1) {
    $Stage1 = $Stage1[0].Group 
}
$Stage2 = $ServerList | Where-Object { $_.Server -like "*wildcard2*" }
If ($Stage2) {
    $Stage2 = $Stage2[0].Group 
}
$GroupsCount = $ServerList.Group | Measure-Object -Maximum
$GroupsCount = $GroupsCount.Maximum
While ($Count -lt $GroupsCount) {
    $Count++
    $Servers = $ServerList | Where-Object { $_.Group -eq $Count }
    Write-Output "`n[$(Get-Date -DisplayHint Time)] Restarting Group: $Count/$GroupsCount"
    Get-VM -Name $Servers.Server | Restart-VMGuest -Confirm:$False | Out-Null 
    If (($Count -eq $Stage1) -OR ($Count -eq $Stage2)) {
        Write-Output "`n[$(Get-Date -DisplayHint Time)] Waiting for $SpecialWaitTime seconds..."
        Start-Sleep -Seconds $SpecialWaitTime
    }
    Else {
        Write-Output "`n[$(Get-Date -DisplayHint Time)] Waiting for $WaitTime seconds..."
        Start-Sleep -Seconds $WaitTime
    }
}

Write-Output "`n[$(Get-Date -DisplayHint Time)] Disconnecting from VM Hosts..."
Disconnect-VIServer -Server * -confirm:$False | Out-Null

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`n[$(Get-Date -DisplayHint Time)] Total Runtime:"$Runtime"`n"
$errorcount = $error.count
Stop-Transcript
If ($errorcount -gt 0) {
    exit 2
}
else {
    exit 0
}