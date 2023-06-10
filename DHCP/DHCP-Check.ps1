<#
.Synopsis
Checks a specified IP Scope usages states
#>


param(
    [Parameter(Mandatory)][String]$IP
)
$DHCPServer = "DHCP-Server"
$Octet = '(?:0?0?[0-9]|0?[1-9][0-9]|1[0-9]{2}|2[0-5][0-5]|2[0-4][0-9])'
[regex] $IPv4Regex = "^(?:$Octet\.){3}$Octet$"

If ($IP -Match $IPv4Regex) {
    Try {
        $SecureCreds = Get-Credential -Credential "RLG\ADMJMcConville"
    }
    Catch {
        Write-Host "`nCredentials required to proceed. Exiting.`n" @SetErrorColours
        Break
    }
    $Session = New-PSSession -ComputerName $DHCPServer -Credential $SecureCreds
    Import-Module -Name DHCPServer -PSSession $Session
    $ScopeDetails = Get-DHCPServerv4Scope -ComputerName $DHCPServer -ScopeID $IP
    $ScopeStats = Get-DHCPServerv4ScopeStatistics -ComputerName $DHCPServer -ScopeID $IP
    Write-Host "`nID:"$ScopeDetails.ScopeID"`nName:"$ScopeDetails.Name"`nStart:"$ScopeDetails.StartRange"`nEnd:"$ScopeDetails.EndRange"`nFree:"$ScopeStats.Free"`nIn Use:"$ScopeStats.InUse"`nReserved:"$ScopeStats.Reserved"`nUtilization:"$ScopeStats.PercentageInUse"%`n"
    
    $CompareName = $ScopeDetails.Name -Split " "
    $FunctionName = $CompareName[4]
    $ScopeList = Get-DHCPServerv4Scope -ComputerName $DHCPServer | Where-Object { $_.Name -Like "*$FunctionName*" }
    $ArrayResults = @()
    ForEach ($Scope in $ScopeList) {
        $ScopeID = $Scope.ScopeID
        $ScopeResults = Get-DHCPServerv4ScopeStatistics -ComputerName $DHCPServer -ScopeID $ScopeID | Where-Object { $_.PercentageInUse -lt 90 }
        If ($ScopeResults) {
            $ArrayAdd = New-Object PSObject
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "ID" -Value $Scope.ScopeID
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Name" -Value $Scope.Name
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Free" -Value $ScopeResults.Free
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Reserved" -Value $ScopeResults.Reserved
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Active" -Value $ScopeResults.InUse
            $ArrayAdd | Add-Member -MemberType NoteProperty -Name "Percentage" -Value $ScopeResults.PercentageInUse
            $ArrayResults += $ArrayAdd
        }
    }
    $ScopeSearchResults = $ArrayResults | Sort-Object Percentage -Desc | Format-Table
    
    $ScopeSearchResults

    Try {
        Remove-PSSession -Session $Session -ErrorAction Stop
    }
    Catch {
        Write-Host "`nError disconnecting the Powershell Session to $DHCPServer. Please disconnect manually, if applicable."
    }
}