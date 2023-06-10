<#
.Synopsis
Takes informations from NewUsers.csv, and creates new user accounts, that are ready to be added to relevant group memberships
#>


param(
    [Switch]$Test,
    [Switch]$Live
)

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
$File = "NewUsers.csv"
$Check = Test-Path $File
If ($Check) {
    $Users = Import-Csv -Path $File
}
Else {
    Write-Output "`n$File does not exist. Exiting."
    Exit
}

$StartTime = Get-Date
Write-Output "`nSetting variables..."

Write-Output "`nRetrieving credentials..."
Try {
    $SecureCreds = Get-Credential -Credential "$AdminUser"
}
Catch {
    Write-Error "`nCredentials required to proceed. Exiting.`n"
    Exit
}

foreach ($User in $Users) {
    If ($Test) {
        $Displayname = "TEST" + $User.Name.Trim()
        $DNLength = $DisplayName.length
        If ($DNLength -lt 20) {
            $SAM = $DisplayName
        }
        Else {
            $SAM = $DisplayName.SubString($DNLength - 20, 20)
        }
    }
    Else {
        $Displayname = $User.Name.Trim()
        $DNLength = $DisplayName.length
        If ($DNLength -lt 21) {
            $SAM = $DisplayName
        }
        Else {
            Write-Error "`nSAM Account name is greater than 20 characters. Cannot create account $DisplayName. Exiting."
            Exit
        }
    }
    $UPN = $Displayname + "@" + $Domain
    $Description = $User.Description.Trim()
    Add-Type -AssemblyName System.Web
    $RandPass = [System.Web.Security.Membership]::GeneratePassword(10, 4)
    While ($RandPass -notmatch "^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[\W]).{8,}$") {
        $RandPass = [System.Web.Security.Membership]::GeneratePassword(10, 4)
    }
    $Password = ConvertTo-SecureString $RandPass -AsPlainText -Force
    $Opts = @{
        Server                = $Domain
        Name                  = $DisplayName
        DisplayName           = $DisplayName
        SAMAccountName        = $SAM
        UserPrincipalName     = $UPN
        Description           = $Description
        AccountPassword       = $Password
        Path                  = $OU
        Enabled               = $TRUE
        ChangePasswordAtLogon = $FALSE
        PasswordNeverExpires  = $TRUE
        OtherAttributes       = @{ 'extensionAttribute7' = 'NO_AUTO_DISABLE' }
    }
    Write-Output "`nCreating $SAM in $OU"
    New-ADUser -Credential $SecureCreds @Opts
    $RandPass = $NULL
}

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`nTotal Runtime:"$Runtime"`n"