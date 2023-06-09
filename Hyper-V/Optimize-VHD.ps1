<#
.Synopsis
Mounts and Optimises VHD disks in Hyper-V to reduce disk size

.Notes
Author: Balthier Lionheart
#>

# Get virtual machines
$VMnames = Get-VM
# Go through each virtual machine
foreach ($VMName in $VMNames) {
	# Get virtual machine name
	$VM = $VMName.name
	# Check if the VM is powered off, and does not have a Snapshot
	if ((Get-VM -Name $VM).State -eq "off" -and $null -eq (Get-VM -Name $VM).ParentCheckpointId) {
		# Get the vHDDs for the virtual machine
		$VHDs = Get-VMHardDiskDrive $VM
		# Go through each of the vHDDs
		foreach ($VHD in $VHDs) {
			# Find the vHDD full file path
			$VHDPath = $VHD.Path
			# Get the filename
			$VHDFile = Split-Path -Path $VHDPath -Leaf -Resolve
			# Get the vHDD file size
			$VHDSize = [math]::ceiling((Get-Item $VHDPath).length / 1GB)
			# Pause for 20 seconds to allow above commands to finish
			Start-Sleep -s 5
			# Show the details on screen
			Write-Host "Virtual Machine: $VM"
			Write-Host "Virtual HDD: $VHDFile"
			Write-Host "Current size: $VHDSize GB"
			# Mount the vHDD
			Mount-VHD -Path $VHDPath -NoDriveLetter -ReadOnly
			# Optimize the vHDD
			Optimize-VHD -Path $VHDPath -Mode Full
			# Get the vHDD file size after optimization process
			$VHDSize = [math]::ceiling((Get-Item $VHDPath).length / 1GB)
			# Show the optimized size
			Write-Host "Optimized size: $VHDSize GB"
			# Dismount the vHDD
			Dismount-VHD -Path $VHDPath
			# Add a line break for presentation purposes
			Write-Host "-------------------------------------"
		}
	}
	# Runs only if the VM is powered on, or contains a Snapshot
	else {
		# Warn user in regards to the VM
		Write-Warning "$VM is powered on or has a snapshot, and cannot be optimized."
		# Add a line break for presentation purposes
		Write-Host "-------------------------------------"
	}
}

