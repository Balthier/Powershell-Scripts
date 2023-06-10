<#
.Synopsis
Restarts the NLA Service on the servers contain in a .txt file
#>


Import-Module VMware.PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -DefaultVIServerMode Multiple -Confirm:$False
$creds = Get-Credential
Connect-VIServer -Server VCENTER1 -AllLinked:$True -Credential $creds

$servers = Get-Content "C:\Temp\servers.txt"
$count = 0
$total = $servers.Count
Foreach ($Server in $Servers) {
    $count++
    Write-Host "[$count/$Total] Sending Command to: $Server"
    Invoke-VMScript -VM $Server -ScriptType Powershell -ScriptText "Restart-Service -Name NlaSvc -Force"
}