# Enable/Disable Logging
Function toggleLogging($toggle) {
    ## Function Variables
    # Current date
    $Date = Get-Date
    # Get the base path of the main/calling script
    $scriptPath = $MyInvocation.PSCommandPath
    # Set the log directory
    $logPath = Split-Path -Parent $scriptPath
    $logDir = "$logPath\Logs"
    # Set the log file
    $logFile = "{0}-{1:d2}-{2:d2}.log" -f $date.year, $date.month, $date.day
	
    # Turn on the logs
    if ($toggle -eq "On") {
        # Create the log directory, if it doesn't exist
        New-Item $LogDir -Type Directory -Force
        try { 
            # Make each log distinguishable
            Add-Content "$logDir\$logFile" "`n"
            Add-Content "$logDir\$logFile" "`nCurrent Date/Time - $Date"
            Add-Content "$logDir\$logFile" "`n"
            # Attempt to start logging
            Start-Transcript -Path "$logDir\$logFile" -Append
        }
        # On fail, stop the previous logging attempt 
        catch { 
            Stop-Transcript
            Add-Content "$logDir\$logFile" "`n"
            Add-Content "$logDir\$logFile" "`nCurrent Date/Time - $Date"
            Add-Content "$logDir\$logFile" "`n"
            Start-Transcript -Path "$logDir\$logFile" -Append
        }
    }
    # Turn off the logs
    if ($toggle -eq "Off") {
        Stop-Transcript
    }
}
Function setColourScheme() {
    $Shell = $Host.UI.RawUI
    $Shell.BackgroundColor = "Black"
    $Shell.ForegroundColor = "Green"
    Clear-Host
}