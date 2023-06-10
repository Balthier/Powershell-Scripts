<#
.Synopsis
Enables the DFS-R Connections on the specified server
#>

Param
(
    [Parameter(Mandatory = $true)][string]$ServerName
)
$dfsr = Get-Service -ComputerName $ServerName -Name DFSR | Select-Object Name, Status, StartType

If (($dfsr.StartType -ne "Disabled") -AND ($dfsr.Status -eq "Running")) {
    Stop-Service -C
    # Get all the replication groups the server is part of 
    $DFSGroupNames = Get-DfsrConnection -SourceComputerName $ServerName | Select-Object GroupName, DestinationComputerName, SourceComputerName, Enabled -ErrorAction Stop
    if ($DFSGroupNames) {
        Write-Host "The following connections for $ServerName, will now be enabled, if they are not already:" -ForegroundColor Green
        $DFSGroupNames | Format-Table
        # enable Replication Group
        ForEach ($DFSGroup in $DfsGroupNames) {
            Set-DfsrConnection $DFSGroup.GroupName -SourceComputerName $DFSGroup.SourceComputerName -DestinationComputerName $DFSGroup.DestinationComputerName -DisableConnection $False | Out-Null
        }
        $DisabledCheck = Get-DfsrConnection -SourceComputerName $ServerName | Where-Object Enabled -EQ $false
        If ($DisabledCheck) {
            Write-Error "The following DFS-R connections could not be enabled: "
            $DisabledCheck | Select-Object SourceComputerName, DestinationComputerName, GroupName, Enabled
        }
        Else {
            Write-Host "The server $ServerName is now enabled for replication with DFS-R for the following groups:" -ForegroundColor Green
            Get-DfsrConnection -SourceComputerName $ServerName | Select-Object GroupName, DestinationComputerName, SourceComputerName, Enabled | Format-Table
        }
    }
    Else {
        Write-Host "No replication groups could be found. Skipping." -ForegroundColor Orange
                
    }
            
}
Else {
    Write-Warning "$ServerName`: DFS-R is either disabled or not currently running. Skipping check for DFS-R connections."
}