<#
.Synopsis
Checks the DCs in the forest for some historical compatibility issues
#>


$StartTime = Get-Date
$GPOResults = @()
$LocalResults = @()
$ForestInfo = Get-ADForest
$AllDomains = ($ForestInfo).Domains
$ForestName = ($ForestInfo).Name

Function Get-GPOCheckResults {
    $GPOArrayAdd = New-Object PSObject
    $GPOArrayAdd | Add-Member -MemberType NoteProperty -Name "Domain" -Value $Domain
    $GPOName2012 = (Get-GPO -All -Domain $Domain | Where-Object DisplayName -Like "*_Domain_Controllers_Custom").DisplayName
    $GPOName2016 = (Get-GPO -All -Domain $Domain | Where-Object DisplayName -Like "*_Domain_Controllers_Custom_2016").DisplayName
    try {
        $GPORaw2012 = [xml](Get-GPOReport -Name "$GPOName2012" -Domain $Domain -ReportType XML)
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
    if ((!$GPORaw2012) -AND (!$GPORaw2016)) {
        Write-Host -ForegroundColor Red $Domain": Unable to retrieve any GPO information"
    }
    $Checks = (
        "2012,RegistrySettings.Registry.Properties,Name,DefaultDomainSupportedEncTypes,Value",
        "2012,RegistrySettings.Registry.Properties,Name,EnableGlobalQueryBlockList,Value",
        "2012,AuditSetting,SubCategoryName,Audit Credential Validation,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Kerberos Authentication Service,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Kerberos Service Ticket Operations,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Other Account Logon Events,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Application Group Management,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Computer Account Management,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Distribution Group Management,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Other Account Management Events,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Security Group Management,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit User Account Management,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Detailed Directory Service Replication,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Directory Service Access,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Directory Service Changes,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Directory Service Replication,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Account Lockout,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit User / Device Claims,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Group Membership,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit IPsec Extended Mode,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit IPsec Main Mode,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit IPsec Quick Mode,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Logoff,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Logon,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Network Policy Server,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Other Logon/Logoff Events,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Special Logon,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Application Generated,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Certification Services,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Detailed File Share,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit File Share,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit File System,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Filtering Platform Connection,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Filtering Platform Packet Drop,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Handle Manipulation,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Kernel Object,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Other Object Access Events,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Registry,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Removable Storage,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit SAM,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Central Access Policy Staging,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Audit Policy Change,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Authentication Policy Change,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Authorization Policy Change,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Filtering Platform Policy Change,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit MPSSVC Rule-Level Policy Change,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Other Policy Change Events,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Non Sensitive Privilege Use,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Other Privilege Use Events,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Sensitive Privilege Use,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit IPsec Driver,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Other System Events,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Security State Change,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit Security System Extension,SettingValue",
        "2012,AuditSetting,SubCategoryName,Audit System Integrity,SettingValue",
        "2016,SecurityOptions,KeyName,*SupportedEncryptionTypes,Name",
        "2016,SecurityOptions,KeyName,*LDAPServerIntegrity,SettingNumber",
        "2016,RegistrySettings.Registry.Properties,Key,*RC4 40/128,Value",
        "2016,RegistrySettings.Registry.Properties,Key,*RC4 56/128,Value",
        "2016,RegistrySettings.Registry.Properties,Key,*RC4 64/128,Value",
        "2016,RegistrySettings.Registry.Properties,Key,*RC4 128/128,Value",
        "2016,SecurityOptions,KeyName,*LmCompatibilityLevel,SettingNumber",
        "2016,SecurityOptions,KeyName,*RestrictRemoteSAM,SettingString",
        "2016,Policy,Name,Configure SMB v1 server,State"
    )
    $AdvAuditCount = 0
    Foreach ($Check in $Checks) {
        $CheckInfo = $Check.Split(",")
        $GPOExp = $CheckInfo[0]
        $GPORootExp = $CheckInfo[1]
        $GPOKeyExp = $CheckInfo[2]
        $GPONameExp = $CheckInfo[3]
        $GPOValueExp = $CheckInfo[4]
        if ($GPOExp -eq "2012") {
            $results = Get-2012GPOResults $GPORootExp $GPOKeyExp $GPONameExp $GPOValueExp $GPORaw2012 $GPORaw2016
            if (!$results) {
                Write-Host -ForegroundColor Yellow $Domain": '$GPONameExp' not found in 2012 GPO. Checking 2016 GPO..."
                $results = Get-2016GPOResults $GPORootExp $GPOKeyExp $GPONameExp $GPOValueExp $GPORaw2012 $GPORaw2016
            }
            elseif ($results) {
                Write-Host $Domain": '$GPONameExp' with value '$results'. Adding to Export"
                if ($GPORootExp -ne "AuditSetting") {
                    $GPOArrayAdd | Add-Member -MemberType NoteProperty -Name $GPONameExp -Value $results
                }
            }
            else {
                if ($GPORootExp -eq "AuditSetting") {
                    $AdvAuditCount++
                }
                else {
                    $GPOArrayAdd | Add-Member -MemberType NoteProperty -Name $GPONameExp -Value "UNKNOWN"
                    Write-Host -ForegroundColor Red $Domain": '$GPONameExp' is not set in either GPO!"
                }
            }
        }
        elseif ($GPOExp -eq "2016") {
            $results = Get-2016GPOResults $GPORootExp $GPOKeyExp $GPONameExp $GPOValueExp $GPORaw2012 $GPORaw2016
            if (!$results) {
                Write-Host -ForegroundColor Yellow $Domain": '$GPONameExp' not found in 2016 GPO. Checking 2012 GPO..."
                $results = Get-2012GPOResults $GPORootExp $GPOKeyExp $GPONameExp $GPOValueExp $GPORaw2012 $GPORaw2016
            }
            elseif ($results) {
                Write-Host $Domain": '$GPONameExp' with value '$results'. Adding to Export"
                if ($GPORootExp -ne "AuditSetting") {
                    $GPOArrayAdd | Add-Member -MemberType NoteProperty -Name $GPONameExp -Value $results
                }
            }
            else {
                if ($GPORootExp -eq "AuditSetting") {
                    $AdvAuditCount++
                }
                else {
                    $GPOArrayAdd | Add-Member -MemberType NoteProperty -Name $GPONameExp -Value "UNKNOWN"
                    Write-Host -ForegroundColor Red $Domain": '$GPONameExp' is not set in either GPO!"
                }
            }
        }
    }
    if ($AdvAuditCount -ne 0) {
        $GPOArrayAdd | Add-Member -MemberType NoteProperty -Name "Advanced Audit Policy" -Value "UNKNOWN"
    }
    else {
        $GPOArrayAdd | Add-Member -MemberType NoteProperty -Name "Advanced Audit Policy" -Value "Configured"
    }
    Return $GPOArrayAdd
}

Function Get-2016GPOResults($GPORootExp, $GPOKeyExp, $GPONameExp, $GPOValueExp, $GPORaw2012, $GPORaw2016) {
    $GPOBaseLoc = $GPORaw2016.GPO.Computer.ExtensionData.Extension
    if ($GPONameExp -eq "*SupportedEncryptionTypes") {
        $results = (($GPOBaseLoc.$GPORootExp | Where-Object { $_.$GPOKeyExp -EQ "$GPONameExp" -OR $_.$GPOKeyExp -like "$GPONameExp" }).Display.DisplayFields.Field | Where-Object Value -EQ true).$GPOValueExp
    }
    elseif ($GPORootExp -like "*.*") {
        $GPOData = $GPOBaseLoc
        $GPORootExpSplit = $GPORootExp.Split(".")
        foreach ($location in $GPORootExpSplit) {
            $GPOData = $GPOData.$location
        }
        $results = ($GPOData | Where-Object { $_.$GPOKeyExp -EQ "$GPONameExp" -OR $_.$GPOKeyExp -like "$GPONameExp" }).$GPOValueExp
        Clear-Variable GPOData, GPORootExpSplit, location
    }
    else {
        $results = ($GPOBaseLoc.$GPORootExp | Where-Object { $_.$GPOKeyExp -EQ "$GPONameExp" -OR $_.$GPOKeyExp -like "$GPONameExp" }).$GPOValueExp
    }
    return [String]$results
}

Function Get-2012GPOResults($GPORootExp, $GPOKeyExp, $GPONameExp, $GPOValueExp, $GPORaw2012, $GPORaw2016) {
    $GPOBaseLoc = $GPORaw2012.GPO.Computer.ExtensionData.Extension
    if ($GPONameExp -eq "*SupportedEncryptionTypes") {
        $results = (($GPOBaseLoc.$GPORootExp | Where-Object { $_.$GPOKeyExp -EQ "$GPONameExp" -OR $_.$GPOKeyExp -like "$GPONameExp" }).Display.DisplayFields.Field | Where-Object Value -EQ true).$GPOValueExp
    }
    elseif ($GPORootExp -like "*.*") {
        $GPOdata = $GPOBaseLoc
        $GPORootExpSplit = $GPORootExp.Split(".")
        foreach ($location in $GPORootExpSplit) {
            $GPOdata = $GPOData.$location
        }
        $results = ($GPOData | Where-Object { $_.$GPOKeyExp -EQ "$GPONameExp" -OR $_.$GPOKeyExp -like "$GPONameExp" }).$GPOValueExp
        Clear-Variable GPOData, GPORootExpSplit, location
    }
    else {
        $results = ($GPOBaseLoc.$GPORootExp | Where-Object { $_.$GPOKeyExp -EQ "$GPONameExp" -OR $_.$GPOKeyExp -like "$GPONameExp" }).$GPOValueExp
    }
    return [String]$results
}

ForEach ($Domain in $AllDomains) {
    Write-Host $Domain": Getting Domain Controllers"
    $GPOAdd = Get-GPOCheckResults
    if (!$GPOAdd) {
        Write-Host $Domain": No GPO Data"
    }
    else {
        $GPOResults += $GPOAdd
    }
    $DCs = Get-ADDomainController -Filter * -Server $Domain
    ForEach ($DC in $DCs) {
        $Server = $DC.HostName
        Write-Host "Running commands on" $Server
        $Add = Invoke-Command -ComputerName $Server -ScriptBlock {
            $DiagChecks = (
                "5 Replication Events",
                "7 Internal Configuration",
                "8 Directory Access",
                "9 Internal Processing",
                "24 DS Schema"
            )
            $DiagChecksCount = 0
            $Server = hostname
            $Domain = (Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).Domain
            $Hostname = $server + "." + $Domain
            $Site = (Get-ADDomainController -Identity $hostname).site
            $AD = (Get-WindowsFeature | Where-Object { $_.Name -eq "AD-Domain-Services" }).InstallState
            $DNS = (Get-WindowsFeature | Where-Object { $_.Name -eq "DNS" }).InstallState
            $DNSServers = (Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq "2" -AND $_.InterfaceAlias -notlike "Loopback*" }).ServerAddresses
            $DNSSuffix = (Get-DnsClientGlobalSetting).SuffixSearchList
            [String]$DNSForwarders = (Get-DnsServerForwarder).IPAddress.IPAddressToString
            [String]$NTPSource = w32tm /query /source
            $SplunkAgent = (Get-WmiObject -Class Win32_Product | Where-Object Name -EQ "UniversalForwarder").Version
            foreach ($DiagCheck in $DiagChecks) {
                $CheckValue = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Ntds\Diagnostics\)."$DiagCheck"
                Write-Host $Server": $DiagCheck currently set as $CheckValue"
                if ($CheckValue -eq "5") {
                    $DiagChecksCount++
                }
            }
            if ($DiagChecksCount) {
                Write-Host -ForegroundColor Yellow $Server": Diagnostic Logging currently turned on"
                $DiagChecksValue = "On"
            }
            else {
                Write-Host -ForegroundColor Green $Server": Diagnostic Logging currently turned off"
                $DiagChecksValue = "Off"
            }
            $ArrayAdd = New-Object PSObject
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Server" -Value $Hostname
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Active Directory" -Value $AD
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS" -Value $DNS
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS Suffix" -Value $DNSSuffix
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS Servers" -Value $DNSServers
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DNS Forwarders" -Value $DNSForwarders
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "NTP Source" -Value $NTPSource
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Splunk Agent" -Value $SplunkAgent
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Site" -Value $Site
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Diagnostic Logging" -Value $DiagChecksValue
            Return $ArrayAdd
        }
        if (!$Add) {
            Write-Host -ForegroundColor Yellow $hostname": No data received from server!"
        }
        else {
            $LocalResults += $Add
        }
    }
}
$DateToday = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$LocalResults | Select-Object * -ExcludeProperty RunspaceId, PSComputerName, PSShowComputerName | Export-Csv -NoTypeInformation "C:\temp\$ForestName-$DateToday-DCUpgradeChecks.csv"
$GPOResults | Select-Object * -ExcludeProperty RunspaceId, PSComputerName | Export-Csv -NoTypeInformation "C:\temp\$ForestName-$DateToday-DCUpgradeGPOChecks.csv"

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Host "`n[$(Get-Date -DisplayHint Time)] Total Runtime:"$Runtime"`n"