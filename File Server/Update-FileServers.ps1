<#
.Synopsis
[UNFINISHED] This will bring down DFS-N/R on the servers from the text files, install windows updates, and bring DFS-R/N back up afterwards

.Notes
Version 0.3
#>

# Set a couple of generic variables
$StartTime = Get-Date
$DateToday = Get-Date -Format "yyyy-MM-dd"
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$LogFile = "$ScriptPath\logs\$DateToday-FLS-Updates.log"
Set-Location $ScriptPath

# Attempt to log the output to a file, exit if it fails after autoremediation attempt
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
    }
}
<#
.Synopsis
   This enables DFS Replication for a file server/ file servers.
.DESCRIPTION
   You can enable all the DFS replication connections going to and from the server
.EXAMPLE
   To use one server you can use the command like so.
   enable-dfsrconnection -servername vcprdgrwwfls03
   To use two servers you can use the command like so.
   enable-dfsrconnection -servername vcprdgrwwfls03, vcprdgrsmfls03
   To use more than two servers you can use the command like so. You can use (get-content c:\temp\fileservers.txt) to read the server names from a text file
   enable-dfsrconnection -servername (get-content c:\temp\fileservers.txt)
#>
function Enable-DFSRConnection {
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string[]]$ServerName
    )
    Begin {
    }
    Process {
        Try {
            foreach ($Server in $ServerName) {
                # Get all the replication groups the server is part of 
                $DFSGroupNames = Get-DfsrConnection -SourceComputerName $server | Select-Object GroupName, DestinationComputerName, SourceComputerName -ErrorAction Stop
                if (!$DFSGroupNames) {
                    Write-Host "No replication groups could be found. Please review your server is a file server and the name is correct" -ForegroundColor Orange
                }
                # enable Replication Group
                $DfsGroupNames | ForEach-Object { Set-DfsrConnection $_.GroupName -SourceComputerName $_.SourceComputerName -DestinationComputerName $_.DestinationComputerName -DisableConnection $False } -ErrorAction Stop
                Write-Host "The server $Server is now enabled for replication with DFSR for the following groups please review the Enabled parameter is set to False" -ForegroundColor Green
            } # End of foreach
        }
        Catch {
            Write-Host "Please review and correct the fault. More details can be found below `n $error[0]" -ForegroundColor Red
        }
    }
    End {
    }
}

<#
.Synopsis
   This disables DFS Replication for a file server/ file servers.
.DESCRIPTION
   You can disable all the DFS replication connections going to and from the server
.EXAMPLE
   To use one server you can use the command like so.
   disable-dfsrconnection -servername vcprdgrwwfls03
   To use two servers you can use the command like so.
   disable-dfsrconnection -servername vcprdgrwwfls03, vcprdgrsmfls03
   To use more than two servers you can use the command like so. You can use (get-content c:\temp\fileservers.txt) to read the server names from a text file
   disable-dfsrconnection -servername (get-content c:\temp\fileservers.txt)
#>
function Disable-DFSRConnection {
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)][string[]]$ServerName
    )
    Begin {
    }
    Process {
        Try {
            foreach ($Server in $ServerName) {
                # Get all the replication groups the server is part of 
                $DFSGroupNames = Get-DfsrConnection -SourceComputerName $server | Select-Object GroupName, DestinationComputerName, SourceComputerName
                if (!$DFSGroupNames) {
                    Write-Host "No replication groups could be found. Please review your server is a file server and the name is correct" -ForegroundColor Red
                }
                # Disable Replication Group
                $DfsGroupNames | ForEach-Object { Set-DfsrConnection $_.GroupName -SourceComputerName $_.SourceComputerName -DestinationComputerName $_.DestinationComputerName -DisableConnection $True }
                Write-Host "The server $Server is now disabled for replication with DFSR for the following groups please review the Enabled parameter is set to False" -ForegroundColor Green
            } # End of foreach
        }
        catch {
            Write-Host "Please review and correct the fault. More details can be found below `n $error[0]"
        }
    }
    End {
    }
}

Function Update-Server($Servers) {
    Import-Module PSWindowsUpdate
    # Utilizes Invoke-WUInstall which creates & runs a scheduled task on the remote machine, bypassing the limitations of of the Windows Update modules restrictions of allowing only local only execution of certain commands
    # Everything in the "-Script { }" block is run locally on the remote machine. E.g. $LogFolder is located on the target/remote machine, as opposed to locally where the script is being run from
    Invoke-WUInstall -ComputerName $Servers -Script {
        # Set variables used by the local execution of the script, on the remote machine
        $LogFolder = 'C:\PSWindowsUpdate'
        $DateToday = Get-Date -Format 'yyyy-MM-dd'
        $TranscriptLog = $LogFolder + '\' + $DateToday + '-transcript.log'
        $LogFile = $DateToday + '-status.txt'
        $ActFile = $DateToday + '-active.txt'
        $FinFile = $DateToday + '-complete.txt'
        $LogPath = $LogFolder + '\' + $LogFile
        $ActPath = $LogFolder + '\' + $ActFile
        $FinPath = $LogFolder + '\' + $FinFile
        # Make sure that the log folder exists, create it if not
        If (!(Test-Path $LogFolder)) {
            New-Item $LogFolder -ItemType Directory -Force
        }

        # Attempt to log the output to a file, exit if it fails after autoremediation attempt
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
    } -Confirm:$false -Verbose
}

Function Get-ServerStatus($Server) {
    Invoke-Command -ComputerName $Server -Script {
        $Attempt = $using:Attempt
        $UpdateErrCount = $using:UpdateErrCount
        $DateToday = Get-Date -Format 'yyyy-MM-dd'
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
                Start-Sleep -s 60
            }
            Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Update process complete. Checking for Failed updates..."
            While (!(Test-Path $LogPath)) {
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - No log found yet. Server may still be rebooting... Waiting 30s..."
                Start-Sleep -s 60
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
            $State = ""
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
                $State = "Reboot"
            }
        }
        Return $State, $UpdateErrCount
    }
}

Function Watch-Servers($AllServers) {
    $Server = ""
    $UpdateErrCount = "0"
    $State = "Initial"
    $Attempt = 0
    Clear-Variable Server
    ForEach ($Server in $AllServers) {
        Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Getting Update Status ($Attempt)..."
        Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - NOTE: This is NOT interferring with the updates on other servers. These will continue silently in the background, and will be checked after this, if applicable..."

        $FunctionData = Get-ServerStatus $Server
        $State = $FunctionData[0]
        $UpdateErrCount = $FunctionData[1]
        $FunctionData = ""

        While ($UpdateErrCount -gt 0) {
            $Attempt++
            If ($Attempt -gt 1) {
                Write-Warning "`n[$(Get-Date -DisplayHint Time)] $Server - $UpdateErrCount failed update(s)... Max retry attempts reached."
                Write-Warning "`n[$(Get-Date -DisplayHint Time)] $Server - Please Update this server manually BEFORE continuing."
                Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - NOTE: This is NOT interferring with the updates on other servers. These will continue silently in the background, and will be checked after this, if applicable..."
                Read-Host "`n[$(Get-Date -DisplayHint Time)] $Server - Press ENTER to continue..."
                Return
            }
            Write-Host "`n[$(Get-Date -DisplayHint Time)] $Server - $UpdateErrCount failed updates... Retrying..."

            $FunctionData = Get-ServerStatus $Server
            $State = $FunctionData[0]
            $UpdateErrCount = $FunctionData[1]
            $FunctionData = ""

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
                $FunctionData = ""
            }
        }
        Clear-Variable Server
    }
}

$Server = ""
$AllServers = Get-Content FileServersAll.txt

Clear-Variable Server
ForEach ($Server in $AllServers) {
    Write-Host "`nSending commands to $Server`n"
    Disable-DFSRConnection -ServerName $Server
    Invoke-Command -ComputerName $Server -ScriptBlock {
        Stop-Service -Name DFSr
    }
}

$AllServers = Get-Content FileServers1.txt
Update-Server $AllServers
Watch-Servers $AllServers

Write-Host "`n[$(Get-Date -DisplayHint Time)] All Servers in FileServers1.txt have been updated."
Read-Host "`n[$(Get-Date -DisplayHint Time)] Press ENTER to continue..."

$AllServers = Get-Content FileServers2.txt
Update-Server $AllServers
Watch-Servers $AllServers

Write-Host "`n[$(Get-Date -DisplayHint Time)] All Servers in FileServers2.txt have been updated."
Write-Host "`n[$(Get-Date -DisplayHint Time)] Please Ping/Confirm all servers are back up, before proceeding."
Read-Host "`n[$(Get-Date -DisplayHint Time)] Press ENTER to continue..."

$AllServers = Get-Content FileServersAll.txt
Clear-Variable Server
ForEach ($Server in $AllServers) {
    Invoke-Command -ComputerName $Server -ScriptBlock {
        Start-Service -Name DFSr
    }
    Enable-DFSRConnection -ServerName $Server
}

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`n[$(Get-Date -DisplayHint Time)] Total Runtime:"$Runtime"`n"
Stop-Transcript