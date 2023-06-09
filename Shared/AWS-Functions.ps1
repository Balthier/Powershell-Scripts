# Verify the Image ID corrisponds to the Image Name specified
function verifyImageId($ImageName) {
	$imageQ = $null
	$image = Get-EC2Image -Filter @{name = 'tag:Name'; values = $ImageName }
	$ImageId = $image | Select-Object -ExpandProperty ImageId
	$Name = $image | Select-Object -ExpandProperty Name
	$Description = $image | Select-Object -ExpandProperty Description
	$State = $image | Select-Object -ExpandProperty State
	$CreatedDate = $image | Select-Object -ExpandProperty CreationDate
	
	Write-Output "
	ID: $Id
	Name: $Name
	Description: $Description
	State: $State
	Created: $CreatedDate"
	
	While ("Y", "N", "Yes", "No" -notcontains $imageQ) { 
		$imageQ = Read-Host "Correct Image? (Y/N)"
	}
	if ("N", "No" -contains $imageQ) {
		$ImageId = $null
		return $ImageId
	}
	else {
		return $ImageId
	}
}

# Import AWS Module & Authenticate
function AWSAuth($awsprofile, $region) {
	Import-Module AWSPowerShell
	Initialize-AWSDefaults -ProfileName $awsprofile -Region $region
}

# Create new VPC
function createVPC($cidr, $incidr, $excidr, $az) {
	
	$vpcResult = New-EC2Vpc -CidrBlock $cidr
	$vpcId = $vpcResult.VpcId
	
	# Enable DNS Support & Hostnames in VPC
	Edit-EC2VpcAttribute -VpcId $vpcId -EnableDnsSupport $true
	Edit-EC2VpcAttribute -VpcId $vpcId -EnableDnsHostnames $true
	
	# Create new Internet Gateway
	$igwResult = New-EC2InternetGateway
	$igwId = $igwResult.InternetGatewayId
	
	# Attach Internet Gateway to VPC
	Add-EC2InternetGateway -InternetGatewayId $igwId -VpcId $vpcId
	
	# Create new Route Table
	$rtResult = New-EC2RouteTable -VpcId $vpcId
	$rtId = $rtResult.RouteTableId
	
	# Create new Route
	$rResult = New-EC2Route -RouteTableId $rtId -GatewayId $igwId -DestinationCidrBlock "0.0.0.0/0"
	
	# Create Internal Subnet for EU-West-1a
	$sn1Result = New-EC2Subnet -VpcId $vpcId -CidrBlock $incidr -AvailabilityZone $az
	$sn1Id = $sn1Result.SubnetId
	Register-EC2RouteTable -RouteTableId $rtId -SubnetId $sn1Id
	
	# Create External Subnet for EU-West-1a
	$sn2Result = New-EC2Subnet -VpcId $vpcId -CidrBlock $excidr -AvailabilityZone $az
	$sn2Id = $sn2Result.SubnetId
	Register-EC2RouteTable -RouteTableId $rtId -SubnetId $sn2Id
	
	# Display results
	Write-Output "
	VPC Setup Complete
	VPC ID : $vpcId
	Internet Gateway ID : $igwId
	Route Table ID : $rtId
	Internal Subnet ID : $sn1Id
	External Subnet ID : $sn2Id
	"
}

# Check $InstanceType is a valid instance type
function checkInstanceType($InstanceType) {
	if (!$InstanceType) {
		$InstanceType = "t2.micro"
	}
	$validTypes = "t2.nano", "t2.micro", "t2.small", "t2.medium", "t2.large", "t2.xlarge", "t2.2xlarge", "m4.large", "m4.xlarge", "m4.2xlarge", "m4.4xlarge", "m4.10xlarge", "m4.16xlarge", "c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge", "r4.large", "r4.xlarge", "r4.2xlarge", "r4.4xlarge", "r4.8xlarge", "r4.16xlarge", "x1.16xlarge", "x1.32xlarge", "d2.xlarge", "d2.2xlarge", "d2.4xlarge", "d2.8xlarge", "i3.large", "i3.xlarge", "i3.2xlarge", "i3.4xlarge", "i3.8xlarge", "i3.16xlarge"
	if ($validTypes -contains $InstanceType) {
		$validity = $true
	}
	else {
		$validity = $false
	}
	return $validity
}

# Create an EC2 instance
function createEC2Instance($ImageId, $minImages, $maxImages, $KeyPair, $InstanceType) {
	$instance = New-EC2Instance -ImageId $ImageId -MinCount $minImages -MaxCount $maxImages -KeyName $KeyPair -InstanceType $InstanceType
	return $instance
}

# Create an RDS DB Instance
function createDBInstance($comp, $az) {
	$dbinstance = NewRDSDBInstance -DBInstanceIdentifier $comp -AllocatedStorage 5 -AutoMinorVersionUpgrade True -AvailabilityZone $az -BackupRetentionPeriod 7 -DBInstanceClass $InstanceType -Engine mysql -EngineVersion 5.7.11 -MasterUsername Balthier -MultiAZ False -PubliclyAccessible False
	return $dbinstance
}

# Create required Security Groups
function createSG($comp, $excidr, $instance, $dbinstance) {
	# Create variables
	$compdb = $comp + "-DB"
	$compweb = $comp + "-Web"
	$instanceid = $instance.RunningInstance.instanceid
	$dbinstanceid = $dbinstance.DBInstanceIdentifier
	
	# Create security group for DB Access
	$dbSG = New-EC2SecurityGroup $compdb -Description "DB Access for $comp"
	
	# Add inbound SQL (Default: 3306) from External Subnet
	Grant-EC2SecurityGroupIngress -GroupName $compdb -IpPermissions @{IpProtocol = "tcp"; FromPort = 3306; ToPort = 3306; IpRanges = @($excidr) }
	
	# Create security group for Web Access
	$wbSG = New-EC2SecurityGroup $compweb -Description "DB Access for $comp"
	
	# Add inbound HTTP/HTTPS from Internet
	Grant-EC2SecurityGroupIngress -GroupName $compweb -IpPermissions @{IpProtocol = "tcp"; FromPort = 80; ToPort = 80; IpRanges = @("0.0.0.0/0") }
	Grant-EC2SecurityGroupIngress -GroupName $compweb -IpPermissions @{IpProtocol = "tcp"; FromPort = 443; ToPort = 443; IpRanges = @("0.0.0.0/0") }
	
	# Assign Security Group to DB Instance
	Edit-RDSDBInstance -DBInstanceIdentifier $dbinstanceid -DBSubnetGroupName $dbSG
	# Assign Security Group to EC2 Instance
	Edit-EC2InstanceAttribute -InstanceId $instanceid -Group $wbSG
}