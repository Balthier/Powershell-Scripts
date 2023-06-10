<#
.Synopsis
Gets the latest Engine definition information currently on Exchange
#>


$ServerList = (Get-MailboxDatabaseCopyStatus * | Select-Object -Unique MailboxServer).MailboxServer | Sort-Object

$Export = @()

ForEach ($Server in $ServerList) {
    $LastChecked, $LastUpdated, $SignatureVersion, $UpdateStatus = $NULL
    $s = New-PSSession -ComputerName $Server
    $data = Invoke-Command -Session $s -ScriptBlock {
        Add-PsSnapin Microsoft.Forefront.Filtering.Management.Powershell
        Get-EngineUpdateInformation | Select-Object LastChecked, LastUpdated, SignatureVersion, UpdateStatus, PSComputerName
    }
    if ($data) {
        $LastChecked = $data.LastChecked
        $LastUpdated = $data.LastUpdated
        $SignatureVersion = $data.SignatureVersion
        $UpdateStatus = $data.UpdateStatus
        $ArrayAdd = New-Object PSObject
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Last Checked" -Value $LastChecked
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Last Updated" -Value $LastUpdated
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Signature Version" -Value $SignatureVersion
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Update Status" -Value $UpdateStatus
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Server" -Value $Server
        $Export += $ArrayAdd
    }
    else {
        $LastChecked = $LastUpdated = $SignatureVersion = $UpdateStatus = "Error"
        $ArrayAdd = New-Object PSObject
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Last Checked" -Value $LastChecked
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Last Updated" -Value $LastUpdated
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Signature Version" -Value $SignatureVersion
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Update Status" -Value $UpdateStatus
        $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Server" -Value $Server
        $Export += $ArrayAdd
    }
    $data = $NULL
}
$Export | Format-Table