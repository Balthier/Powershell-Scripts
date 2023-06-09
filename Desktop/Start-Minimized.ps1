<#
.Synopsis
A quick PowerShell script for starting program in a minimized state.

.Parameter Program
Specifies the program to launch

.Parameter Wait
Specifies the time period, in seconds, for the program to wait before launching

.Notes
Author: Balthier Lionheart
Created: 2015-02-16
Modified: 2015-02-18
#>

[CmdletBinding()]
param(
	[string]$program,
	[string]$wait
)

if ($wait) {
	Start-Sleep -s $wait
}
if ($program) {
	cmd.exe /c start /b /min $program
}
