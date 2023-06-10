<#
.Synopsis
Retrieves a list of folders in $SrcHome, and migrates them evenly across the destination folders in $NewHome. NOTE: Check the line comments for live/test actions.
#>


# Function to process each folder
Function processItem($Item) {
    $ItemName = $Item
    $Src = "$SrcHome\$Item"
    $DestFound = $NULL
    ForEach ($FolderPath in $NewHome) {
        $DestFull = Get-ChildItem -Path "$FolderPath\" -Directory | Select-Object -ExpandProperty name
        $FolderCount = $DestFull.count

        If (($FolderCount -lt $LowestCount) -OR (!$LowestCount)) {
            $LowestCountPath = $FolderPath
            $LowestCount = $FolderCount
        }
        ForEach ($Dest in $DestFull) {
            # Check for an existing folder
            If ($Dest -eq $ItemName) {
                $DestFinal = "$FolderPath\$Dest"
            }
            # Check if there was a match
            If ($DestFinal) {
                Write-Host "[$(Get-Date -DisplayHint Time)] Found result for '$ItemName' in '$FolderPath' ('$DestFinal')"
                # Run the RoboCopy command with the options specified
                # UNCOMMENT THE BELOW IN LIVE
                RoboCopy $Src $destFinal /MIR /e /zb /DCOPY:T /copyALL /FP /r:3 /w:3 /MT:32 /log+:\\LOGSERVER\C$\Logs\log_ShareName3.log /V /TEE
                $DestFound = $TRUE
            }
            # Reset the variable to null, ready for the next loop round
            $DestFinal = ""
        }
    }
    If (!$DestFound) {
        Write-Host "[$(Get-Date -DisplayHint Time)] Target Directory for '$ItemName' will be '$LowestCountPath\$ItemName' (Shared folder count: $LowestCount)"
        $DestFinal = "$LowestCountPath\$ItemName"
        # MAKE NEW FOLDER AS A TEST - REMOVE FOR LIVE
        # New-Item -Path $LowestCountPath -Name $ItemName -ItemType "directory"
        # UNCOMMENT THE BELOW IN LIVE
        RoboCopy $Src $destFinal /MIR /e /zb /DCOPY:T /copyALL /FP /r:3 /w:3 /MT:32 /log+:\\LOGSERVER\C$\Logs\log_ShareName3.log /V /TEE

    }
    
}

# Set required variables
$SrcHome = "\\HOMESERVER1\Users"
$NewHome = @(
    "\\HOMESERVER2\UserHome1",
    "\\HOMESERVER3\UserHome2",
    "\\HOMESERVER2\UserHome3",
    "\\HOMESERVER3\UserHome4"
)

# Get a full list of directories in $SrcHome01
$SrcHomeFolders = Get-ChildItem -Path $SrcHome -Directory

# Gather a list of directories that don't contain "disabled"
$NonDisabled = $SrcHomeFolders | Where-Object { $_.Name -NotLike "*disabled" }

# Run through $NonDisabled for an existing folder
$TestCount = 0
$NonDisabled | ForEach-Object {
    $TestCount++
    If ($TestCount -lt 30) {
        $Item = $_.Name
        ProcessItem($Item)
    }
}