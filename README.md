# Merge all the aVHDXs into the parent VHDX
simple powershell script to merge aVHDX to the parent VHDX

This script is written in PowerShell and is used to merge AVHDX files into their parent VHDX files for virtual machines in Hyper-V. 

The script first defines the paths for the Virtual Machine folder, Backup folder, and Log file. It then uses the Get-ChildItem cmdlet to get all AVHDX files in the Virtual Machine folder. The script then loops through each AVHDX file, gets the path of the AVHDX file and its parent VHDX file, gets the name of the virtual machine, and gets the virtual machine object.  Then, it  checks if the virtual machine is in the "Off" state and creates a backup of the virtual machine before merging the AVHDX file into the parent VHDX file. 

Finally, It then checks the status of the merge and updates the virtual machine to point to the VHDX file and starts the virtual machine. If any errors occur, they are logged to the log file.

DespairRaven.
