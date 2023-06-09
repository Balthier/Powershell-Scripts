<#
.Synopsis
Launches a new AWS Instance **Incomplete**

.Notes
Author: Balthier Lionheart
#>

# Include the functions
. "$PSScriptRoot\..\AWS-Functions.ps1"
. "$PSScriptRoot\..\Shared\Common-Functions.ps1"

# Turn on logging to file
toggleLogging("On")

# Create the main variables
$awsprofile = Read-Host "Access Profile"
# **** Uncomment this line, to manually specify Region **** #
# $region = Read-Host "Region"
$region = "eu-west-2"
$az = Read-Host "Availability Zone"
$comp = Read-Host "Company"
$compdb = $comp + "-DB"
$compweb = $comp + "-Web"
$cidr = Read-Host "CIDR"
$incidr = Read-Host "Internal CIDR"
$excidr = Read-Host "External CIDR"
$minImages = "1"
$maxImages = Read-Host "# of Additional EC2 Instances"
$KeyPair = Read-Host "KeyPair Name"
$InstanceType = Read-Host "Instance Type (Default: t2.micro)"

# Authenticate with AWS
AWSAuth($awsprofile, $region)

# Verify correct image selected
while ($ImageId = $null) {
	$ImageName = Read-Host "AMI Name"
	verifyImageId($ImageName)
}

# Check valid instance type
checkInstanceType($InstanceType)

# Create the required VPC, and 2 subnets
createVPC($cidr, $incidr, $excidr, $az)

# Create the EC2 instance
createEC2Instance($ImageId, $minImages, $maxImages, $KeyPair, $InstanceType)

# Create the RDS DB Instance
createDBInstance($comp, $az)

# Create a security group
createSG($compdb, $excidr, $instance, $dbinstance)

# Turn off logging, cleanly
toggleLogging("Off")