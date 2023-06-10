<#
.Synopsis
Retrieves a list of users that are a member of an SD Holder group, in all domains, and outputs to csv: SDHolderMembers.csv
#>


$StartTime = Get-Date
Write-Output "`nSetting variables..."
$Users = @()
$SDHolders = @(
    "Account Operators",
    "Administrators",
    "Backup Operators",
    "Cert Publishers",
    "Domain Admins",
    "Domain Controllers",
    "Enterprise Admins",
    "Enterprise Key Admins",
    "Key Admins",
    "Print Operators",
    "Read-only Domain Controllers",
    "Schema Admins",
    "Server Operators"
)
$ErrorActionPreference = "SilentlyContinue"

Write-Output "`nGetting available Domains..."
$Domains = (Get-ADForest).domains

Write-Output "`nSearching Domains for AdminSDHolder group membership..."
$ArrayResults = @()
$SDHolders | ForEach-Object {
    $Group = $_
    ForEach ($Domain in $Domains) {
        $FoundUsers = Get-ADGroupMember -Identity "$Group" -Server $Domain -Recursive | Get-ADUser -Properties * -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        If ($FoundUsers) {
            $Users += $FoundUsers
            ForEach ($user in $FoundUsers) {
                $ArrayAdd = New-Object PSObject
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "SD Domain" -Value $Domain
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Group" -Value $Group
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "User Location" -Value $user.CanonicalName
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Name" -Value $user.SAMAccountName
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Given Name" -Value $user.GivenName
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Surname" -Value $user.Surname
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $user.Enabled
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "AdminCount" -Value $user.adminCount
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Last Logon Date" -Value $user.LastLogonDate
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Description" -Value $user.Description
                $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Member Of" -Value $user.MemberOf
                $ArrayResults += $ArrayAdd
            } 
        }
    }
}
Write-Output "`nExporting to CSV..."
$ArrayResults | Export-Csv SDHolderMembers.csv -NoTypeInformation

$Runtime = (Get-Date) - $StartTime
$Runtime = $Runtime -f ("HH:mm:ss")
Write-Output "`nTotal Runtime:"$Runtime"`n"