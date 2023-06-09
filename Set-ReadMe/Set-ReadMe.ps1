<#
.Synopsis
Re-Generates the README.md file with the latest information from all scripts
#>

$Dir = $PSScriptRoot
$ReadMeLoc = "..\README.md"
$Folders = Get-ChildItem "$Dir\.." -Directory | Where-Object { $_.Fullname -NotLike "*Shared*" -and $_.Fullname -NotLike "*To Be Sorted*" }
$NewContent = @()

[collections.arraylist]$ReadMeContent = (Get-Content $ReadMeLoc).split("`n")
$Count = 0

While ($ReadMeContent[$Count] -ne "# Script List") {
    $NewContent += $ReadMeContent[$Count]
    $Count++
}
$NewContent += "# Script List

## Powershell"

ForEach ($Folder in $Folders) {
    $FolderName = $folder -replace '(.*)Powershell-Scripts\\', ""
    $NewContent += "`n### $FolderName"
    $FolderPath = $Folder.FullName
    $Files = Get-ChildItem -Path $FolderPath -File -Recurse -Include *.ps1

    ForEach ($File in $Files) {
        if ($file -notlike "*Functions.ps1") {
            Try {
                $HelpInfo = Get-Help "$File"
                $Synopsis = $HelpInfo.Synopsis
            }
            Catch {
                Write-Host "No help content in $File"
            }

            $Path = $File.FullName
            [collections.arraylist]$Tree = $Path -Split "\\"
            $Count = 0

            While ($Tree[$Count] -ne "Powershell-Scripts") {
                $Tree.RemoveAt($Count)
            }

            Clear-Variable -Name Count
            $Path = ($Tree -join "\").replace("Powershell-Scripts\", "")
            $Name = "[" + ($Path -Replace "Powershell\\", "") + "]"
            $Link = "(" + ($Path -Replace " ", "%20") + ")  "
            $Hyperlink = $Name + $Link

            $NewContent += $Hyperlink
            $NewContent += $Synopsis + "`n"

            Clear-Variable -Name Name, Link
        }
    }
}

Set-Content -Path $ReadMeLoc -Value $NewContent