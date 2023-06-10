<#
.Synopsis
[UNFINISHED] Attempts to migrate databases to passive/active nodes, and install windows updates
#>


#Requires -Version 5.1
Function Move-ExchangeDBs() {
    param(
        [Switch]$Failover,
        [Switch]$Failback
    )
    If (($Failover) -OR ($Failback)) {
        $ErrCount = 0
        If ($Failover) {
            $Option = "Failover"
        }
        If ($Failback) {
            $Option = "Failback"
        }
        $Folder = "C:\Temp"
        $FileBefore = "$Folder\Exchange-$Option-Before.csv"
        $FileAfter = "$Folder\Exchange-$Option-After.csv"
        Write-Host "Retrieving current configuration..."
        $BeforeSetup = Get-MailboxDatabaseCopyStatus * | Select-Object MailboxServer, ActivationPreference | Sort-Object ActivationPreference
        $BeforeSetup | Format-Table -AutoSize
        Write-Host "Exporting CSV to $FileBefore"
        $BeforeSetup | Export-Csv $FileBefore -NoTypeInformation
        $Databases = (Get-MailboxDatabase).Name

        ForEach ($Database in $Databases) {
            Write-Host "Processing $Database..."
            $DBInfo = Get-MailboxDatabaseCopyStatus $Database | Select-Object Name, Status, MailboxServer, ActivationPreference, ContentIndexState | Sort-Object ActivationPreference
            $Primary = $DBInfo | Where-Object { $_.ActivationPreference -eq 1 }
            $PrimaryServer = $Primary.MailboxServer
            $Secondary = $DBInfo | Where-Object { $_.ActivationPreference -eq $DBInfo.Count }
            $SecondaryServer = $Secondary.MailboxServer
            If ($Secondary) {
                If ($Failover) {
                    If ($Primary.Status -eq "Mounted") {
                        If (($Primary.ContentIndexState -eq "Healthy") -AND ($Secondary.Status -eq "Healthy") -AND ($Secondary.ContentIndexState -eq "Healthy")) {
                            Move-ActiveMailboxDatabase $Database -ActivateOnServer $SecondaryServer
                        }
                        Else {
                            Write-Error "Either the Primary or Secondary database is not in a Healthy State. See Below for more Details."
                            $DBInfo | Format-Table -AutoSize
                            $ErrCount++
                        }
                    }
                    Else {
                        Write-Error "$Database not mounted on primary server $PrimaryServer"
                        $ErrCount++
                    }
                }
                If ($Failback) {
                    If ($Secondary.Status -eq "Mounted") {
                        If (($Primary.ContentIndexState -eq "Healthy") -AND ($Primary.Status -eq "Healthy") -AND ($Secondary.ContentIndexState -eq "Healthy")) {
                            Move-ActiveMailboxDatabase $Database -ActivateOnServer $PrimaryServer
                        }
                        Else {
                            Write-Error "Either the Primary or Secondary database is not in a Healthy State. See Below for more Details."
                            $DBInfo | Format-Table -AutoSize
                            $ErrCount++
                        }
                    }
                    Else {
                        Write-Error "$Database not mounted on secondary server $SecondaryServer"
                        $ErrCount++
                    }
                }
            }
            Else {
                Write-Host "$Database has no secondary associated. Skipping..."
            }
        }
        Write-Host "Retrieving current configuration..."
        Start-Sleep -s 5
        $AfterSetup = Get-MailboxDatabaseCopyStatus * | Select-Object Name, Status, MailboxServer, ActivationPreference, ContentIndexState | Sort-Object ActivationPreference
        $AfterSetup | Format-Table -AutoSize
        Write-Host "Exporting CSV to $FileAfter"
        $AfterSetup | Export-Csv $FileAfter -NoTypeInformation
        Return $ErrCount
    }
}

Function Publish-UpdateModule($Server) {
    Write-Host "Checking $Server for the Windows Update Module..."
    $ModuleDir = "\\$Server\C$\Windows\System32\WindowsPowerShell\v1.0\Modules\PSWindowsUpdate"
    $ModuleSrcCheck = Test-Path ".\PSWindowsUpdate\PSWindowsUpdate.psm1"
    $ModuleDstCheck = Test-Path "$ModuleDir\PSWindowsUpdate.psm1"

    If ($ModuleSrcCheck) {
        If (!$ModuleDstCheck) {
            Write-Host "Windows Update module not found. Copying PSWindowsUpdate to $ModuleDir..."
            Try {
                Copy-Item -Path .\PSWindowsUpdate -Destination $ModuleDir -Recurse
            }
            Catch {
                Write-Error "Error copying module to $ModuleDir. Please do this manually before continuing."
                Read-Host “Press ENTER to continue...”
                $ModuleDstReCheck = Test-Path "$ModuleDir\PSWindowsUpdate.psm1"
                If (!$ModuleDstReCheck) {
                    Write-Error "Error locating remote modules. Exiting."
                    Exit
                }
            }
        }
        Else {
            Write-Host "Windows Update module found at $ModuleDir..."
        }
    }
    Else {
        Write-Error "Source Module Folder not found. Please place the PSWindowsUpdate module folder in the same location as this script."
        Exit
    }
}

Function Update-Server($Servers) {
    # Accepted 2 / Downloaded 3 / Installed 4 / Failed
    Import-Module PSWindowsUpdate
    $UpdateTest = Get-WUList -ComputerName $Servers -Verbose
    If ($UpdateTest) {
        Invoke-WUJob -ComputerName $Servers -Script {
            $LogFolder = 'C:\PSWindowsUpdate'
            $DateToday = Get-Date -Format 'yyyy-MM-dd'
            $TranscriptLog = $LogFolder + '\' + $DateToday + '-transcript.log'
            $LogFile = $DateToday + '-status.txt'
            $ActFile = $DateToday + '-active.txt'
            $FinFile = $DateToday + '-complete.txt'
            $LogPath = $LogFolder + '\' + $LogFile
            $ActPath = $LogFolder + '\' + $ActFile
            $FinPath = $LogFolder + '\' + $FinFile
            If (!(Test-Path $LogFolder)) {
                New-Item $LogFolder -ItemType Directory -Force
            }
            Try {
                Start-Transcript -Path $TranscriptLog -Append -NoClobber -IncludeInvocationHeader
            }
            Catch {
                Stop-Trascript
                Try {
                    Start-Transcript -Path $TranscriptLog -Append -NoClobber -IncludeInvocationHeader
                }
                Catch {
                    Write-Error '`n['+$(Get-Date -DisplayHint Time)+'] '$Server' - Error creating log file.'
                }
            }
            Import-Module PSWindowsUpdate
            $Server = $env:COMPUTERNAME
            New-Item $ActPath -ItemType File -Force
            Get-WUInstall -AcceptAll -IgnoreReboot -Verbose | Out-File $LogPath -Append
            While ((Test-Path $ActPath)) {
                $ActivityCheck = Get-WUInstallerStatus
                Write-Host '`n['+$(Get-Date -DisplayHint Time)+'] '$Server' - Checking status of Windows Updates Installer...'
                If (!$ActivityCheck) {
                    Write-Host '`n['+$(Get-Date -DisplayHint Time)+'] '$Server' - Unable to get installer status...'
                }
                ElseIf ($ActivityCheck -eq 'Installer is ready.') {
                    Write-Host '`n['+$(Get-Date -DisplayHint Time)+'] '$Server' - Update Installer Ready...'
                    Remove-Item $ActPath
                    Start-Sleep -s 5
                    $RebootStatus = Get-WURebootStatus -Silent
                    If ($RebootStatus) {
                        New-Item $FinPath -ItemType File -Force
                        Write-Host '`n['+$(Get-Date -DisplayHint Time)+'] '$Server' - Reboot required for updates...'
                        Start-Sleep -s 5
                        Restart-Computer -Force
                    }
                    Else {
                        New-Item $FinPath -ItemType File -Force
                        Write-Host '`n['+$(Get-Date -DisplayHint Time)+'] '$Server' - Reboot not required for updates...'
                    }
                }
                ElseIf ($ActivityCheck -eq 'Installer is Busy.') {
                    Write-Host '`n['+$(Get-Date -DisplayHint Time)+'] '$Server' - Update Installer Busy...'
                    Start-Sleep -s 30
                }
            }
            Stop-Transcript
        } -Confirm:$false -Verbose -RunNow
    }
}

Function Get-ServerStatus($Server) {
    Invoke-Command -ComputerName $Server -Script {
        $Attempt = $using:Attempt
        $UpdateErrCount = $using:UpdateErrCount
        $DateToday = $using:DateToday
        $LogFolder = "C:\PSWindowsUpdate"
        $LogFile = "$DateToday-status.txt"
        $LogPath = "$LogFolder\$LogFile"
        $FinFile = "$DateToday-complete.txt"
        $FinPath = "$LogFolder\$FinFile"
        $Server = $using:Server
        $State = $using:State
        If ($State -eq "Initial") {
            $UpdateErrCount = 0
            While (!(Test-Path $FinPath)) {
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Updates still in progress..."
                Start-Sleep -s 30
            }
            Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Update process complete. Checking for Failed updates..."
            While (!(Test-Path $LogPath)) {
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - No log found yet. Server may still be rebooting... Waiting 30s..."
                Start-Sleep -s 30
            }
            $FailedCheck = Get-Item $LogPath | Select-String "Failed" -SimpleMatch | Select-Object -Property Line
            If (!$FailedCheck) {
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - No Failed Updates located in $LogPath"
            }
            Else {
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - The following updates failed: "
                $FailedCheck | Select-Object Line, PSComputerName | Format-Table -AutoSize
                $UpdateErrCount = $FailedCheck.Count
            }
            Clear-Variable $State
        }
        Else {
            If ($Attempt -eq 1) {
                $LastBootTime = (gcim Win32_OperatingSystem).LastBootUpTime
                $Uptime = (Get-Date) - $LastBootTime
                If (($Uptime.Days) -gt 0) {
                    $AddHours = $Uptime.Days * 24
                    $Uptime.hours = ($Uptime.hours) + $AddHours
                }
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Attempting automatic restart..."
                wuauclt /detectnow /force
                wuauclt /resetauthorization /force
                Restart-Computer -Force
                $State = "Reboot"
            }
        }
        Return $State, $UpdateErrCount
    }
}

Write-Host "Importing Exchange modules..."
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://WCPRDSHSMEDW01/PowerShell/ -Authentication Kerberos
Import-PSSession $Session -DisableNameChecking

$ServerList = Get-MailboxDatabaseCopyStatus * | Select-Object -Unique MailboxServer, ActivationPreference
$AllServers = $ServerList.MailboxServer
$PriServers = ($ServerList | Where-Object ActivationPreference -EQ 1).MailboxServer
$SecServers = ($ServerList | Where-Object ActivationPreference -NE 1).MailboxServer

Clear-Variable $Server
ForEach ($Server in $AllServers) {
    Publish-UpdateModule $Server
}

$DateToday = Get-Date -Format "yyyy-MM-dd"

Update-Server $SecServers

Clear-Variable $Server
ForEach ($Server in $SecServers) {
    $State = "Initial"
    $Attempt = 0

    Write-Host "$Server - Getting Update Status ($Attempt)..."

    $FunctionData = Get-ServerStatus $Server
    $State = $FunctionData[0]
    $UpdateErrCount = $FunctionData[1]
    Clear-Variable $FunctionData

    While ($UpdateErrCount -gt 0) {
        $Attempt++
        If ($Attempt -gt 1) {
            Write-Warning "`n[$(Get-Date -DisplayHint Time)] $Server - $UpdateErrCount failed update(s)... Max retry attempts reached."
            Write-Warning "`n[$(Get-Date -DisplayHint Time)] $Server - Please Update this server manually BEFORE continuing."
            Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - NOTE: This is NOT interferring with the updates on other servers. These will continue silently in the background, and will be checked after this, if applicable..."
            Read-Host “`n[$(Get-Date -DisplayHint Time)] $Server - Press ENTER to continue...”
            Return
        }
        Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - $UpdateErrCount failed updates... Retrying..."

        $FunctionData = Get-ServerStatus $Server
        $State = $FunctionData[0]
        $UpdateErrCount = $FunctionData[1]
        Clear-Variable $FunctionData

        If ($State -eq "Reboot") {
            $Online = $FALSE
            While (!($Online)) {
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Waiting for connection to remote host..."
                Start-Sleep -s 30
                $Online = Test-Connection -Count 1 -ComputerName $Server -Quiet
                $State = "Initial"
            }

            Update-Server $Server

            Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Getting Update Status ($Attempt)..."

            $FunctionData = Get-ServerStatus $Server
            $State = $FunctionData[0]
            $UpdateErrCount = $FunctionData[1]
            Clear-Variable $FunctionData
        }
    }
}

Write-Host "Failing over the exchange databases to the secondary servers..."
$DBMoveStatus = Move-ExchangeDBs -Failover
If ($DBMoveStatus) {
    Write-Warning "Errors encountered during the database migration! Please rectify these before continuing!"
    Read-Host “Press ENTER to continue...”
}

Write-Host "Updating Primary Servers..."
Update-Server $PriServers
Start-Sleep -s 30

Clear-Variable $Server
ForEach ($Server in $SecServers) {
    $State = "Initial"
    $Attempt = 0

    Write-Host "$Server - Getting Update Status ($Attempt)..."

    $FunctionData = Get-ServerStatus $Server
    $State = $FunctionData[0]
    $UpdateErrCount = $FunctionData[1]
    Clear-Variable $FunctionData

    While ($UpdateErrCount -gt 0) {
        $Attempt++
        If ($Attempt -gt 1) {
            Write-Warning "`n[$(Get-Date -DisplayHint Time)] $Server - $UpdateErrCount failed update(s)... Max retry attempts reached."
            Write-Warning "`n[$(Get-Date -DisplayHint Time)] $Server - Please Update this server manually BEFORE continuing."
            Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - NOTE: This is NOT interferring with the updates on other servers. These will continue silently in the background, and will be checked after this, if applicable..."
            Read-Host “`n[$(Get-Date -DisplayHint Time)] $Server - Press ENTER to continue...”
            Return
        }
        Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - $UpdateErrCount failed updates... Retrying..."

        $FunctionData = Get-ServerStatus $Server
        $State = $FunctionData[0]
        $UpdateErrCount = $FunctionData[1]
        Clear-Variable $FunctionData

        If ($State -eq "Reboot") {
            $Online = $FALSE
            While (!($Online)) {
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Waiting for connection to remote host..."
                Start-Sleep -s 30
                $Online = Test-Connection -Count 1 -ComputerName $Server -Quiet
                $State = "Initial"
            }

            Update-Server $Server

            Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Getting Update Status ($Attempt)..."

            $FunctionData = Get-ServerStatus $Server
            $State = $FunctionData[0]
            $UpdateErrCount = $FunctionData[1]
            Clear-Variable $FunctionData
        }
    }
}

Write-Host "Failing back the exchange databases to the primary servers..."
$DBMoveStatus = Move-ExchangeDBs -Failback
If ($DBMoveStatus) {
    Write-Warning "Errors encountered during the database migration! Please rectify these before continuing!"
    Read-Host “Press ENTER to continue...”
}