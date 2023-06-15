<#
.Synopsis
Starts a KCC and runs AD replication in both directions, for all Domain Controllers in the Forest
#>


$StartTime = Get-Date
$WaitTime = 300

$Sites = (Get-ADForest).Sites
ForEach ($Site in $Sites) {
    $DCList = Get-ADDomainController -Filter { site -eq $site }
    if ($DCList) {
        Write-Host "DCs found in $Site. Initiating KCC."
        repadmin /kcc site:$Site
        Clear-Variable DCList
    }
    else {
        Write-Host "No DCs found in $Site. Skipping KCC."
    }
}

Write-Host "KCC initiated against all sites. Waiting for $WaitTime seconds, to allow KCC to complete"
Start-Sleep -Seconds $WaitTime

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