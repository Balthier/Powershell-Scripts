<#
.Synopsis
Starts an AD replication in both directions, for all Domain Controllers in the Forest
#>

$StartTime = Get-Date
$AllDomains = (Get-ADForest).Domains

ForEach ($Domain in $AllDomains) {
    Write-Host $Domain": Getting Domain Controllers"
    $DCs = Get-ADDomainController -Filter * -Server $Domain
    ForEach ($DC in $DCs) {
        $hostname = $DC.hostname
        Write-Host $hostname": Sending commands"
        Invoke-Command -ComputerName $hostname -ScriptBlock {
            repadmin /syncall /Aed
            repadmin /syncall /APed
        }
    }
}
$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Host "`n[$(Get-Date -DisplayHint Time)] Total Runtime:"$Runtime"`n"