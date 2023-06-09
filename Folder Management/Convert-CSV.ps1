<#
.Synopsis
Converts a CSV file into XLS
#>

$csvFolder = ".\PCInfo"
$csvFile = "\system-info.csv"
$xlsFile = "\system-info.xls"
$csv = "$csvFolder$csvFile"
$xlsFolder = $csvFolder
$xls = "$xlsFolder$xlsFile"
$csv = "$csvFolder$csvFile"
$xlsCheck = Test-Path $xls

function convertCSV() {
	if ($xlsCheck) {
		Remove-Item -Force -path $xls
	}
	$xl = new-object -comobject excel.application
	$xl.visible = $true
	$Workbook = $xl.workbooks.open("$csv")
	$Workbook.SaveAs("$xls", 1)
	$Workbook.Saved = $True
	$xl.Quit()
}

convertCSV