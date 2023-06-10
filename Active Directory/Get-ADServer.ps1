<#
.Synopsis
Attempts to find all the servers ($Servers) in various known domains via AD, and DNS. Passwords need adding to lines 54-64.
#>


$servers = @(
    "SERVER1", 
    "SERVER2"
)

$Domains = @{
    "DOMAIN1.FQ.DN" = "DOMAIN-SHORT"
    "DOMAIN2.FQ.DN" = "DOMAIN-SHORT"
    "DOMAIN3.FQ.DN" = "DOMAIN-SHORT"
}

$User = "DOMAIN1\ACCOUNT"
$PWord = ConvertTo-SecureString -String "PASSWORD" -AsPlainText -Force
$DomainCreds1 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$User = "DOMAIN2\ACCOUNT"
$PWord = ConvertTo-SecureString -String "PASSWORD" -AsPlainText -Force
$DomainCreds2 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$User = "DOMAIN3\ACCOUNT"
$PWord = ConvertTo-SecureString -String "PASSWORD" -AsPlainText -Force
$DomainCreds3 = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

$errors = @()
$ADresults = @()
$DNSresults = @()
$Domains.GetEnumerator() | ForEach-Object {
    $Domain = $($_.Key)
    if ($domain -in "Domain1") {
        $Creds = $DomainCreds1
    }
    elseif ($domain -in "Domain2") {
        $Creds = $DomainCreds2
    }
    elseif ($domain -in "Domain3") {
        $Creds = $DomainCreds3
    }
    Write-Output "`nBeginning search in $Domain..."
    $servers | ForEach-Object {
        $Server = $_
        try {
            if ($Creds) {
                $ADresults += Get-ADComputer -Server $Domain -Identity $server -Credential $Creds | Select-Object DistinguishedName, DNSHostName, Enabled
            }
            Else {
                $ADresults += Get-ADComputer -Server $Domain -Identity $server | Select-Object DNSHostName, DistinguishedName, Enabled
            }
        }
        catch {
            $errors += "$Domain Error: " + $_ + " Using Creds: " + $Creds

        }
        try {
            $DNSresults += Resolve-DnsName $Server -Server $Domain -QuickTimeout -NoRecursion -ErrorAction Stop
        }
        catch {
            $errors += "$Domain Error: " + $_ + " Using Creds: " + $Creds
        }
    }
    if ($Creds) {
        Remove-Variable -Name Creds
    }
}
Write-Host "Active Directory: "
$ADresults | Sort-Object DNSHostName | Format-Table

Write-Host "DNS: "
$DNSresults | Sort-Object Name | Select-Object -Unique Name, IPAddress