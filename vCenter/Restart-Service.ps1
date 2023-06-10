<#
.Synopsis
Restarts the NLA Service on the servers contain in a .txt file - Contains basic error checking, and tracking of failed servers
#>


Import-Module VMware.PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -DefaultVIServerMode Multiple -Confirm:$False
$creds = Get-Credential
Connect-VIServer -Server VCPRDGRSMVCN01 -AllLinked:$True -Credential $creds

$servers = Get-Content "C:\Temp\servers.txt"
$count = 0
$total = $servers.Count
Foreach ($Server in $Servers) {
    $count++
    Write-Host "[$count/$Total] Sending Commands to: $Server"
    
    try {
        $NetProfileBefore = (Invoke-VMScript -VM $Server -ScriptType Powershell -ScriptText "(Get-NetConnectionProfile).NetworkCategory").ScriptOutput
    }
    catch {
        Write-Host "[$count/$Total] Error connecting to: $Server"
        $FailedServers += $server
        return
    }

    If ($NetProfileBefore -ne "DomainAuthenticated") {
        Write-Host "[$count/$Total] Network profile: $NetProfileBefore - Restarting NLA service on $Server"
        Invoke-VMScript -VM $Server -ScriptType Powershell -ScriptText "Restart-Service -Name NlaSvc -Force"

        $NetProfileAfter = (Invoke-VMScript -VM $Server -ScriptType Powershell -ScriptText "(Get-NetConnectionProfile).NetworkCategory").ScriptOutput

        If ($NetProfileAfter -ne "DomainAuthenticated") {
            Write-Host "[$count/$Total] Network Profile on the following server is still reporting as Non-Domain: $Server"
            $FailedServers += $server
        }
    }
    else {
        Write-Host "[$count/$Total] Network Profile on the following server is already Domain Authenticated: $Server"
    }
}

$FailedServers