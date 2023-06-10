<#
.Synopsis
Checks the DCs in the forest for some historical compatibility issues
#>

$GPOResults = @()
$Results = @()
$ForestInfo = Get-ADForest
$AllDomains = ($ForestInfo).Domains
$ForestName = ($ForestInfo).Name

Function Get-GPOCheckResults {
    $GPOName = (Get-GPO -All -Domain $Domain | Where-Object DisplayName -Like "*_Domain_Controllers_Custom").DisplayName
    $GPOName2016 = (Get-GPO -All -Domain $Domain | Where-Object DisplayName -Like "*_Domain_Controllers_Custom_2016").DisplayName
    try {
        $GPORaw = [xml](Get-GPOReport -Name "$GPOName" -Domain $Domain -ReportType XML)
    }
    catch {
        Write-Host -ForegroundColor Yellow $Domain": Error getting GPO information."
    }
    try {
        $GPORaw2016 = [xml](Get-GPOReport -Name "$GPOName2016" -Domain $Domain -ReportType XML)
    }
    catch {
        Write-Host -ForegroundColor Yellow $Domain": Error getting 2016 GPO information."
    }
    if ((!$GPORaw) -AND (!$GPORaw2016)) {
        Write-Host -ForegroundColor Red $Domain": Unable to retrieve any GPO information"
    }
    
    $GPOBaseLoc = $GPORaw.GPO.Computer.ExtensionData.Extension
    $GPOBaseLoc2016 = $GPORaw2016.GPO.Computer.ExtensionData.Extension

    $DefaultDomainSupportedEncTypes = ($GPOBaseLoc.RegistrySettings.Registry | Where-Object Name -EQ "DefaultDomainSupportedEncTypes").Properties.Value
    if (!$DefaultDomainSupportedEncTypes) {
        Write-Host -ForegroundColor Yellow $Domain": DefaultDomainSupportedEncTypes is not set in the Standard GPO"
        $DefaultDomainSupportedEncTypes = ($GPOBaseLoc.RegistrySettings.Registry | Where-Object Name -EQ "DefaultDomainSupportedEncTypes").Properties.Value
        if (!$DefaultDomainSupportedEncTypes) {
            Write-Host -ForegroundColor Red $Domain": DefaultDomainSupportedEncTypes is not set in either GPO!"
        }
    }
	
    $WPAD = ($GPOBaseLoc.RegistrySettings.Registry | Where-Object Name -EQ "EnableGlobalQueryBlockList").Properties.Value
    if (!$WPAD) {
        Write-Host -ForegroundColor Yellow $Domain": EnableGlobalQueryBlockList is not set in the Standard GPO"
        $WPAD = ($GPOBaseLoc.RegistrySettings.Registry | Where-Object Name -EQ "EnableGlobalQueryBlockList").Properties.Value
        if (!$WPAD) {
            Write-Host -ForegroundColor Red $Domain": EnableGlobalQueryBlockList is not set in either GPO!"
        }
    }

    [String]$SupportedEncryption = (($GPOBaseLoc.SecurityOptions | Where-Object KeyName -Like "*SupportedEncryptionTypes").Display.DisplayFields.Field | Where-Object Value -EQ true).Name
    if (!$SupportedEncryption) {
        [String]$SupportedEncryption = (($GPOBaseLoc2016.SecurityOptions | Where-Object KeyName -Like "*SupportedEncryptionTypes").Display.DisplayFields.Field | Where-Object Value -EQ true).Name
        if (!$SupportedEncryption) {
            Write-Host -ForegroundColor Red $Domain": SupportedEncryptionTypes is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": SupportedEncryptionTypes is set in the Standard GPO!"
    }

    $LDAPSigning = ($GPOBaseLoc.SecurityOptions | Where-Object KeyName -Like "*LDAPServerIntegrity").Display.DisplayString
    if (!$LDAPSigning) {
        $LDAPSigning = ($GPOBaseLoc2016.SecurityOptions | Where-Object KeyName -Like "*LDAPServerIntegrity").Display.DisplayString
        if (!$LDAPSigning) {
            Write-Host -ForegroundColor Red $Domain": LDAPServerIntegrity is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": LDAPServerIntegrity is set in the Standard GPO!"
    }

    $RC440 = ($GPOBaseLoc.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 40/128").Value
    if (!$RC440) {
        $RC440 = ($GPOBaseLoc2016.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 40/128").Value
        if (!$RC440) {
            Write-Host -ForegroundColor Red $Domain": RC4 40/128 is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": RC4 40/128 is set in the Standard GPO!"
    }
	
    $RC456 = ($GPOBaseLoc.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 56/128").Value
    if (!$RC456) {
        $RC456 = ($GPOBaseLoc2016.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 56/128").Value
        if (!$RC456) {
            Write-Host -ForegroundColor Red $Domain": RC4 56/128 is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": RC4 56/128 is set in the Standard GPO!"
    }
	
    $RC464 = ($GPOBaseLoc.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 64/128").Value
    if (!$RC464) {
        $RC464 = ($GPOBaseLoc2016.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 64/128").Value
        if (!$RC464) {
            Write-Host -ForegroundColor Red $Domain": RC4 64/128 is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": RC4 64/128 is set in the Standard GPO!"
    }
	
    $RC4128 = ($GPOBaseLoc.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 128/128").Value
    if (!$RC4128) {
        $RC4128 = ($GPOBaseLoc2016.RegistrySettings.Registry.Properties | Where-Object key -Like "*RC4 128/128").Value
        if (!$RC4128) {
            Write-Host -ForegroundColor Red $Domain": RC4 128/128 is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": RC4 128/128 is set in the Standard GPO!"
    }
	
    $NTLMv1 = ($GPOBaseLoc.SecurityOptions | Where-Object KeyName -Like "*LmCompatibilityLevel").Display.DisplayString
    if (!$NTLMv1) {
        $NTLMv1 = ($GPOBaseLoc2016.SecurityOptions | Where-Object KeyName -Like "*LmCompatibilityLevel").Display.DisplayString
        if (!$NTLMv1) {
            Write-Host -ForegroundColor Red $Domain": LmCompatibilityLevel is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": LmCompatibilityLevel is set in the Standard GPO!"
    }

    $RemoteSAM = ($GPOBaseLoc.SecurityOptions | Where-Object KeyName -Like "*RestrictRemoteSAM").Display.DisplayString
    if (!$RemoteSAM) {
        $RemoteSAM = ($GPOBaseLoc2016.SecurityOptions | Where-Object KeyName -Like "*RestrictRemoteSAM").Display.DisplayString
        if (!$RemoteSAM) {
            Write-Host -ForegroundColor Red $Domain": RestrictRemoteSAM is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": RestrictRemoteSAM is set in the Standard GPO!"
    }

    $SMBv1 = ($GPOBaseLoc.Policy | Where-Object Name -EQ "Configure SMB v1 server").State
    if (!$SMBv1) {
        $SMBv1 = ($GPOBaseLoc2016.Policy | Where-Object Name -EQ "Configure SMB v1 server").State
        if (!$SMBv1) {
            Write-Host -ForegroundColor Red $Domain": SMBv1 is not set in either GPO!"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow $Domain": SMBv1 is set in the Standard GPO!"
    }

    $ArrayAdd = New-Object PSObject
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Domain" -Value $Domain
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Kerberos Patch" -Value $DefaultDomainSupportedEncTypes
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "WPAD" -Value $WPAD
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "LDAP Signing" -Value $LDAPSigning
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "NTLMv1" -Value $NTLMv1
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Remote SAM" -Value $RemoteSAM
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Supported Encryption" -Value $SupportedEncryption
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "SMBv1" -Value $SMBv1
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "RC4 40/128" -Value $RC440
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "RC4 56/128" -Value $RC456
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "RC4 64/128" -Value $RC464
    $ArrayAdd | Add-Member -MemberType NoteProperty -Name "RC4 128/128" -Value $RC4128
    Return $ArrayAdd
}

ForEach ($Domain in $AllDomains) {
    Write-Host $Domain": Getting Domain Controllers"
    $DCs = Get-ADDomainController -Filter * -Server $Domain
    $GPOAdd = Get-GPOCheckResults
    if (!$GPOAdd) {
        Write-Host $Domain": No GPO Data"
    }
    else {
        $GPOResults += $GPOAdd
    }
    ForEach ($DC in $DCs) {
        $Server = $DC.HostName
        Write-Host "Running commands on" $Server
        $Add = Invoke-Command -ComputerName $Server -ScriptBlock {
            $Server = hostname
            $Domain = (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain
            $Hostname = $server + "." + $Domain
            $Site = (Get-ADDomainController -Identity $hostname).site
            $AD = (Get-WindowsFeature | Where-Object { $_.Name -eq "AD-Domain-Services" }).InstallState
            $DNS = (Get-WindowsFeature | Where-Object { $_.Name -eq "DNS" }).InstallState
            $DNSServers = (Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq "2" -AND $_.InterfaceAlias -notlike "Loopback*" }).ServerAddresses
            $DNSSuffix = (Get-DnsClientGlobalSetting).SuffixSearchList
            $SplunkAgent = (Get-WmiObject -Class Win32_Product | Where-Object Name -EQ "UniversalForwarder").Version

            $ArrayAdd = New-Object PSObject
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Server" -Value $Hostname
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Active Directory" -Value $AD
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS" -Value $DNS
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS Suffix" -Value $DNSSuffix
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS Servers" -Value $DNSServers
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Splunk Agent" -Value $SplunkAgent
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Site" -Value $Site
            Return $ArrayAdd
        }
        if (!$Add) {
            Write-Host -ForegroundColor Yellow $hostname": No data received from server!"
        }
        else {
            $Results += $Add
        }
    }
}

$DateToday = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$Results | Select-Object * -ExcludeProperty RunspaceId, PSComputerName, PSShowComputerName | Export-Csv -NoTypeInformation "C:\temp\$ForestName-$DateToday-DCUpgradeChecks.csv"
$GPOResults | Select-Object * -ExcludeProperty RunspaceId, PSComputerName | Export-Csv -NoTypeInformation "C:\temp\$ForestName-$DateToday-DCUpgradeGPOChecks.csv"