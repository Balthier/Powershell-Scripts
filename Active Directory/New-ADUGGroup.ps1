<#
.Synopsis
Takes information from NewUGGroups.csv, and creates new security groups with the specified users
#>


param(
    [Switch]$Test,
    [Switch]$Live
)

$StartTime = Get-Date

If (($Test) -AND (!$Live)) {
    $OU = "OU=users,DC=testdomain,DC=com"
    $Domain = "testdomain.com"
    $AdminUser = "TESTDOMAIN\ADMINACCOUNT"
}

ElseIf ((!$Test) -AND ($Live)) {
    $OU = "OU=users,DC=domain,DC=com"
    $Domain = "domain.com"
    $AdminUser = "DOMAIN\ADMINACCOUNT"
}
ElseIf ((!$Test) -AND (!$Live)) {
    Write-Error "No parameters specified. -Live or -Test required."
    Exit
}
Else {
    Write-Error "Please select only 1 switch. Either -Live or -Test."
    Exit
}
$File = "NewUGGroups.csv"
$Check = Test-Path $File
If ($Check) {
    $UGGroups = Import-Csv -Path $File
}
Else {
    Write-Output "`n$File does not exist. Exiting."
    Exit
}

Write-Output "`nSetting variables..."

Write-Output "`nRetrieving credentials..."
Try {
    $SecureCreds = Get-Credential -Credential "$AdminUser"
}
Catch {
    Write-Error "`nCredentials required to proceed. Exiting.`n"
    Exit
}

Foreach ($UGGroup in $UGGroups) {
    If ($Test) {
        $Displayname = "TEST" + $UGGroup.group.Trim()
    }
    Else {
        $Displayname = $UGGroup.group.Trim()
    }
    $ManagedBy = $UGGroup.ManagedBy
    $Description = $UGGroup.description
    $Members = $UGGroup.Members.split(";")
    $Opts = @{
        Credential    = $SecureCreds
        Server        = $Domain
        Name          = $DisplayName
        DisplayName   = $DisplayName
        GroupCategory = "Security"
        GroupScope    = "Universal"
        Description   = $Description
        Path          = $OU
        ManagedBy     = $ManagedBy
    }
    New-ADGroup @Opts
    $Opts = @{
        Credential = $SecureCreds
        Server     = $Domain
        Identity   = $DisplayName
    }
    $Members | ForEach-Object { Add-ADGroupMember @Opts -Members $_ }
}

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`nTotal Runtime:"$Runtime"`n"