<#
.Synopsis
Checks what Kerberos Encryption ciphers are enabled on the server (Server 2016)
#>

param(
    [Array]$Servers
)
If ($Servers) {
    $Servers
    Invoke-Command -ComputerName $Servers -ScriptBlock {
        $Folders = Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\
        $Data = @()
        foreach ($Folder in $Folders) {
            $Path = ($Folder.Name).Replace("HKEY_LOCAL_MACHINE", "HKLM:")
            $Values = Get-ItemProperty -Path $Path -Name Enabled | Select-Object PSChildName, Enabled | Where-Object PSChildName -Like "*RC4*"
            $Name = $Values.PSChildName
            $Setting = $Values.Enabled
            if ($Name) {
                $ArrayAdd = New-Object PSObject
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Encryption" -Value $Name
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Setting" -Value $Setting
                $Data += $ArrayAdd
            }
        }

        $Value = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters\ -Name SupportedEncryptionTypes
        $Setting = $Value.SupportedEncryptionTypes
        Clear-Variable -Name ArrayAdd
        $ArrayAdd = New-Object PSObject
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Encryption" -Value "RC4/AES GPO"
        If ($Setting -eq "2147483644") {
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Setting" -Value "1"
        }
        else {
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Setting" -Value "Unknown"
        }
        $Data += $ArrayAdd
        $Data
    }
}
else {
    $Folders = Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\
    $Data = @()
    foreach ($Folder in $Folders) {
        $Path = ($Folder.Name).Replace("HKEY_LOCAL_MACHINE", "HKLM:")
        $Values = Get-ItemProperty -Path $Path -Name Enabled | Select-Object PSChildName, Enabled | Where-Object PSChildName -Like "*RC4*"
        $Name = $Values.PSChildName
        $Setting = $Values.Enabled
        if ($Name) {
            $ArrayAdd = New-Object PSObject
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Encryption" -Value $Name
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Setting" -Value $Setting
            $Data += $ArrayAdd
        }
    }

    $Value = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters\ -Name SupportedEncryptionTypes
    $Setting = $Value.SupportedEncryptionTypes
    Clear-Variable -Name ArrayAdd
    $ArrayAdd = New-Object PSObject
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Encryption" -Value "RC4/AES GPO"
    If ($Setting -eq "2147483644") {
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Setting" -Value "1"
    }
    else {
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Setting" -Value "Unknown"
    }
    $Data += $ArrayAdd
    $Data
}