<#
.Synopsis
Retrieves a list of user accounts that have problematic characters included. E.g. Tab, New Lines, etc.
#>


$Domains = @{
    "DOMAIN1.FQ.DN" = "DOMAIN-SHORT"
    "DOMAIN2.FQ.DN" = "DOMAIN-SHORT"
    "DOMAIN3.FQ.DN" = "DOMAIN-SHORT"
}

$Export = @()

$Domains.GetEnumerator() | ForEach-Object {
    $Domain = $($_.Key)
   	$DomainShort = $($_.Value)
    $regex = "\p{C}|\p{Zl}|\p{Zp}|\p{M}"
    Write-Host "Checking $Domain"
    Get-ADUser -Server $Domain -Filter * -Properties Name, Description, MailAddress, Mail, displayName, groupType, SAMAccountName | Where-Object { $_.description -match $regex -OR $_.MailAddress -match $regex -OR $_.mail -match $regex -OR $_.displayName -match $regex -OR $_.groupType -match $regex -OR $_.SAMAccountName -match $regex } | ForEach-Object { 
        $user = $_
        $Name = $user.Name
        $Desc = $user.Description
        $MailAdd = $user.MailAddress
        $Mail = $user.Mail
        $Display = $user.DisplayName
        $GType = $user.GroupType
        $SAM = $user.SAMAccountName
        $ArrayAdd = New-Object PSObject
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Domain" -Value $DomainShort
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Name" -Value $Name
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Description" -Value $Desc
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "MailAddress" -Value $MailAdd
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Mail" -Value $Mail
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $Display
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "GroupType" -Value $GType
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "SAMAccountName" -Value $SAM
        $Export += $ArrayAdd
    }
}
$DateToday = Get-Date -Format "yyyy-MM-dd"
$Export | Export-Csv "C:\temp\$DateToday - Get-ADUser-IllegalChar.csv" -Append -NoTypeInformation