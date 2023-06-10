
<#
.Synopsis
Checks Domain Controllers for the SMBv1 Feature, and installs/enables the configuration
#>

$Results = @()
$SMBConfigServers = @()
$SMBStatusServers = @()
$AllDomains = (Get-ADForest).Domains

ForEach ($Domain in $AllDomains) {
    Write-Host $Domain": Getting Domain Controllers"
    $DCs = Get-ADDomainController -Filter * -Server $Domain
    ForEach ($DC in $DCs) {
        $hostname = $DC.hostname
        Write-Host $hostname": Configuring server"
        $Add = Invoke-Command -ComputerName $hostname -ScriptBlock {
            $SMBConfig = Get-SmbServerConfiguration
            $SMBStatus = Get-WindowsFeature FS-SMB1
            $Server = hostname
            $Domain = (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain
            $hostname = $server + "." + $Domain
            $ArrayAdd = New-Object PSObject
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Server" -Value $hostname
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "SMBStatus" -Value $SMBStatus.InstallState
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "SMBConfig" -Value $SMBConfig.EnableSMB1Protocol
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DC" -Value $ActiveDC
            Return $ArrayAdd
        }
        if (!$Add) {
            Write-Host $hostname": NULL Data"
        }
        else {
            $Results += $Add
            $InstallStatus = ($Add.SMBStatus).Value
            $ConfigStatus = $Add.SMBConfig
            $Server = $Add.Server
            If ($InstallStatus -eq "Available") {
                $SMBStatusServers += $Server
            }
            If ($ConfigStatus -eq $false) {
                $SMBConfigServers += $Server
            }
            Clear-Variable -Name Add
        }
    }
}

$Results | Select-Object Server, SMBStatus, SMBConfig | Format-Table

If ($SMBStatusServers) {
    Write-Host "The following Servers require the SMBv1 feature: `n"
    $SMBStatusServers

    $Ad01Continue = Read-Host "Install Feature? (Y/N)"
    While ("Y", "N", "Yes", "No" -notcontains $Ad01Continue) { 
        $Ad01Continue = Read-Host "Install Feature? (Y/N)"
    }
    if ("Y", "Yes" -contains $Ad01Continue) {
        Foreach ($Server in $SMBStatusServers) {
            Invoke-Command -ComputerName $Server -ScriptBlock {
                Write-Host "Installing the SMBv1 Feature on $Server"
                Get-WindowsFeature FS-SMB1 | Install-WindowsFeature
                Write-Host "Enabling SMBv1 on $Server"
                Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force
            }
        }
        Write-Host "Please reboot the servers as required."
    }
    Else {
        Write-Host "Skipped..."
    }
}
Else {
    Write-Host "All servers have the feature installed"
}

If ($SMBConfigServers) {
    Write-Host "The following Servers require SMBv1 enabling: `n"
    $SMBConfigServers

    $Ad02Continue = Read-Host "Enable?? (Y/N)"
    While ("Y", "N", "Yes", "No" -notcontains $Ad02Continue) { 
        $Ad02Continue = Read-Host "Enable? (Y/N)"
    }
    if ("Y", "Yes" -contains $Ad02Continue) {
        Foreach ($Server in $SMBConfigServers) {
            Invoke-Command -ComputerName $Server -ScriptBlock {
                Write-Host "Enabling SMBv1 on $Server"
                Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force
            }
        }
        Write-Host "Please reboot the servers as required."
    }
    Else {
        Write-Host "Skipped..."
    }
}
Else {
    Write-Host "All servers have been enabled"
}