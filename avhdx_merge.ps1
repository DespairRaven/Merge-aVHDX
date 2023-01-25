# Define the path to the Virtual Machine folder
$vmPath = pwd | Select-Object | %{$_.ProviderPath}

# Define the path for the Backup folder
$backupPath = pwd | Select-Object | %{$_.ProviderPath}

# Define the path for the Log file
$logPath = pwd | Select-Object | %{$_.ProviderPath} + "\Logs\MergeLogs.txt"

# Get all AVHDX files
$avhdxFiles = Get-ChildItem -Path $vmPath -Filter "*.avhdx"

# Loop through each AVHDX file
foreach ($avhdxFile in $avhdxFiles) {

    # Get the path of the AVHDX file
    $avhdxPath = $avhdxFile.FullName

    # Get the path of the parent VHDX file
    $vhdxPath = $avhdxPath -replace ".avhdx",".vhdx"

    # Get the name of the virtual machine
    $vmName = ($avhdxPath -split "\\")[-2]

    # Get the virtual machine object
    $vm = Get-VM -Name $vmName
    
    # Validate the virtual machine state
    if ((Get-VM -Name $vmName).State -ne "Off") {
        Write-Host "The virtual machine $vmName is not in the Off state. Please shut it down before running the script."
        continue
    }
    
    # Create a backup of the virtual machine
    try {
        $backupName = $vmName + "_" + (Get-Date -Format "yyyyMMdd_HHmmss")
        $backup = Export-VM -Name $vmName -Path $backupPath -Name $backupName
        Write-Host "A backup of the virtual machine $vmName has been created at $backupPath\$backupName" | Out-File $logPath -Append
    } catch {
        Write-Host "An error occurred while creating a backup of the virtual machine $vmName: $_" | Out-File $logPath -Append
        continue
    }

    # Merge the AVHDX file into the parent VHDX file
    try {
        Merge-VHD -DestinationPath $vhdxPath -SourcePath $avhdxPath -Confirm:$false
        Write-Host "The merge of $avhdxPath was successful." | Out-File $logPath -Append
    } catch {
        Write-Host "An error occurred while merging $avhdxPath: $_" | Out-File $logPath -Append
        continue
    }

    # Check the status of the merge
    $mergeStatus = (Get-VHD -Path $vhdxPath).MergeStatus

    # Check if the merge was successful
    if ($mergeStatus -eq "Completed") {

        # Get the virtual hard disk object for the virtual machine
        $vmHardDisk = $vm | Get-VMHardDiskDrive | Where-Object {$_.Path -eq $avhdxPath}

        # Update the virtual machine to point to the VHDX file
        try {
            $vmHardDisk | Set-VMHardDiskDrive -Path $vhdxPath
            Write-Host "The virtual machine $vmName has been reconfigured to point to $vhdxPath." | Out-File $logPath -Append
        } catch {
            Write-Host "An error occurred while reconfiguring the virtual machine $vmName: $_" | Out-File $logPath -Append
            continue
        }

        # Start the virtual machine
        try {
            Start-VM -Name $vmName
            Write-Host "The virtual machine $vmName has been started." | Out-File $logPath -Append
        } catch {
            Write-Host "An error occurred while starting the virtual machine $vmName: $_" | Out-File $logPath -Append
        }
    } else {
        Write-Host "The merge of $avhdxPath was not successful. The merge status is: $mergeStatus" | Out-File $logPath -Append
    }
}
