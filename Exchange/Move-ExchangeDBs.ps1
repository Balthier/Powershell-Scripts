<#
.Synopsis
Migrates the active copy of all Exchange databases to/from the passive nodes
#>


param(
    [Switch]$Failover,
    [Switch]$Failback
)
If (($Failover) -OR ($Failback)) {
    Write-Host "Importing Exchange modules..."
    if (!(Get-PSSnapin | Where-Object { $_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010" })) {
        try {
            Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction STOP
        }
        catch {
            Write-Host "Error Loading Exchange Modules"
            Write-Warning $_.Exception.Message
        }
        . $env:ExchangeInstallPath\bin\RemoteExchange.ps1
        Connect-ExchangeServer -auto -AllowClobber
    }
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
    $BeforeSetup = Get-MailboxDatabaseCopyStatus * | Select-Object Name, Status, MailboxServer, ActivationPreference, ContentIndexState | Sort-Object ActivationPreference
    $BeforeSetup | Format-Table -AutoSize
    Write-Host "Exporting CSV to $FileBefore"
    $BeforeSetup | Export-CSV $FileBefore -NoTypeInformation
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
                    }
                }
                Else {
                    Write-Error "$Database not mounted on primary server $PrimaryServer"
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
                    }
                }
                Else {
                    Write-Error "$Database not mounted on secondary server $SecondaryServer"
                }
            }
        }
        Else {
            Write-Host "$Database has no secondary associated. Skipping..."
        }
    }
    Write-Host "Retrieving current configuration..."
    $AfterSetup = Get-MailboxDatabaseCopyStatus * | Select-Object Name, Status, MailboxServer, ActivationPreference, ContentIndexState | Sort-Object ActivationPreference
    $AfterSetup | Format-Table -AutoSize
    Write-Host "Exporting CSV to $FileAfter"
    Start-Sleep -s 5
    $AfterSetup | Export-CSV $FileAfter -NoTypeInformation
}