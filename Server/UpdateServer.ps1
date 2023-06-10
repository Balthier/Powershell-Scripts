<#
.Synopsis
This is a simple Powershell script to update a list of specified servers

.Description
By default, no parameters are required.

The script requires a .txt file containing a list of server names.

.Parameter File
Specifies the txt file which contains the list of servers to update

Default value: UpdateList.txt

.Parameter ThrottleLimit
Specifies the maximum number of concurrent connections

Default value: 10

.Example
./UpdateServer.ps1 -File "CustomUpdateList.txt"
This will restart all servers within "CustomUpdateList.txt"

.Example
./UpdateServer.ps1
If -File is not specified, the default file "UpdateList.txt" will be specified

#>


param(
    [String]$File = "UpdateList.txt",
    [int]$ThrottleLimit = "10"
)
$DateToday = Get-Date -Format "yyyy-MM-dd"
$DateYesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$LogFile = "ServerUpdate - $DateToday.log"
Try {
    Start-Transcript -Path $LogFile -Append -NoClobber -IncludeInvocationHeader -ErrorAction Stop
}
Catch {
    Stop-Trascript
    Try {
        Start-Transcript -Path $LogFile -Append -NoClobber -IncludeInvocationHeader -ErrorAction Stop
    }
    Catch {
        Write-Error "`nError creating log file. Exiting."
    }
}

$StartTime = Get-Date
Write-Output "`nSetting variables..."
$AdminUser = "DOMAIN\ADMINACCOUNT"

$PathCheck = Test-Path "$File"
If ($PathCheck) {
    Write-Output "`nRetrieving VMs to restart from file $File..."
    $ServerList = Get-Content $File -ErrorAction Stop
}
Else {
    Write-Error "`nCannot locate $File. Exiting.`n"
    Stop-Transcript
    Break
}

Write-Output "`nRetrieving credentials..."
Try {
    $SecureCreds = Get-Credential -Credential "$AdminUser"
}
Catch {
    Write-Error "`nCredentials required to proceed. Exiting.`n"
    Stop-Transcript
    Break
}

Write-Output "`nSending update commands..."
$InstalledToday = Invoke-Command -ComputerName $ServerList -Credential $SecureCreds -ScriptBlock {
    $OS = Get-WmiObject win32_operatingSystem | Select-Object caption
    If (($OS -Like "*2008*") -OR ($OS -Like "*2012*")) {
        #WUAUCLT /ResetAuthorization
        #WUAUCLT /SelfUpdateManaged
        #WUAUCLT /DetectNow
        #WUAUCLT /SelfUpdateManaged /UpdateNow
        #Start-Sleep 60
        #WUAUCLT /ReportNow
        $Trigger = New-JobTrigger -Once -At (Get-Date)
        $User = "NT AUTHORITY\SYSTEM"
        $Action = New-ScheduledTaskAction -Execute "WUAUCLT.exe" -Argument "/DetectNow /UpdateNow /ReportNow"
        $Settings = New-ScheduledTaskSettingsSet -DeleteExpiredTaskAfter (New-TimeSpan -Hours 1).Hours
        Register-ScheduledTask -TaskName "WUAUCLT-DetectNow-UpdateNow-ReportNow" -Trigger $Trigger -User $User -Action $Action -Settings $Settings -RunLevel Highest –Force
        Start-Sleep 60
    }
    If (($OS -Like "*2016*") -OR ($OS -Like "*2019*")) {
        USOClient.exe ScanInstallWait
        USOClient.exe StartInstall
        Start-Sleep 60
        USOClient.exe RestartDevice
    }
    $Hotfixes = Get-HotFix | Select-Object hotfixid, description, installedby, @{label = "InstalledOn"; e = { [DateTime]::Parse($_.psbase.properties["installedon"].value, $([System.Globalization.CultureInfo]::GetCultureInfo("en-US"))) } }
    $Hotfixes | Where-Object { (($_.InstalledOn[0]).ToString("yyyy-MM-dd") -eq "$DateToday") -OR (($_.InstalledOn[0]).ToString("yyyy-MM-dd") -eq "$DateYesterday") }
}
If ($InstalledToday) {
    Write-Output "`nThe following updates have been installed Today, or Yesterday:`n"
    $InstalledToday | Sort-Object $_.hotfixid | Format-Table PSComputerName, HotfixID, Description, InstalledBy, InstalledOn
}
Else {
    Write-Output "`nNo Updates have been installed Today, or Yesterday.`n"
}

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`nTotal Runtime:"$Runtime"`n"
Stop-Transcript