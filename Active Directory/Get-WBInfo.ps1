<#
.Synopsis
Retreives a backup policies from Windows Backup, on Domain Controllers
#>

$AllDomains = (Get-ADForest).Domains
$summary = @()
ForEach ($Domain in $AllDomains) {
    Write-Host $Domain": Getting Domain Controllers"
    $DCs = Get-ADDomainController -Filter * -Server $Domain
    ForEach ($DC in $DCs) {
        $hostname = $DC.hostname
        Write-Host $hostname": Checking System State Backup Configuration"
        $output = Invoke-Command -ComputerName $hostname -ScriptBlock { 
            $FeatureInstalled = (Get-WindowsFeature Windows-Server-Backup).Installed
            If ($FeatureInstalled) {
                $values = Get-WBPolicy | Select-Object PSComputerName, Schedule, BackupTargets, VolumesToBackup, BMR, SystemState
                return $Values
            }
        }
        If ($output) {
            $summary += $output
            Clear-Variable -Name output
        }
        Else {
        }
    }
}