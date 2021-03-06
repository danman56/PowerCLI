# Description: Ghetto migration script. Move VMs to new Cluster
# Add in the PowerCLI CMDLET
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
# Connect to the vCenter using passthru
Connect-VIServer 10.0.11.179 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

# Lets create an array to store the virtual machine whom have an RDM attached
$RDM_VMs = @()

# Time to get all the virtual machines within the Production_Test Cluster
# store results in the variable $VMs
$vms = Get-VM -Location Production_Test

# Next lets go ahead and find out who has RDMs
# Then we add them to the RDM_VMs array
foreach($vm in ($vms | get-view ))
{   
    # walk through the hardware devices
    foreach($dev in $vm.Config.Hardware.Device)
    {
        # for each hardware check to see if it is a virtual disk
        if(($dev.gettype()).Name -eq "VirtualDisk")
        {
            # for each virtual disk; determine if it is a RDM (checking for both physical or virtual)
            if(($dev.Backing.CompatibilityMode -eq “physicalMode”) -or ($dev.Backing.CompatibilityMode -eq “virtualMode”))
            {
                # Once found add to array
                $RDM_VMs += $vm.Name
            }
      
        }
    }
}

foreach($vm in ($vms | get-view))
{
    if($vm.Guest.ToolsRunningStatus -eq "guestToolsRunning")
    {
        # Tools are found so gracefully shutdown the vm
        Shutdown-VMGuest -VM $vm.Name -Confirm:$false | Out-Null
        
        # Does the RDM array not contain our current vm?
        if($RDM_VMs -notcontains $vm.Name)
        {
            # Migrate Virtual Machine to a random host in "New Prod-Test"
            Move-VM -VM $vm.Name -Confirm:$false -Destination (Get-Cluster -Name "New Prod-Test" | Get-VMHost | Get-Random) | Out-Null
            Start-VM -VM $vm.Name -Confirm:$false -RunAsync | Out-Null
        }
    }
    elseif($vm.Guest.ToolsRunningStatus -eq "guestToolsNotRunning")
    {
        # Tools not found so poweroff vm
        Stop-VM -VM $vm.Name -Confirm:$false | Out-Null
        
        # Does the RDM array not contain our current vm?
        if($RDM_VMs -notcontains $vm.Name)
        {
            # Migrate Virtual Machine to a random host in "New Prod-Test"
            Move-VM -VM $vm.Name -Confirm:$false -Destination (Get-Cluster -Name "New Prod-Test" | Get-VMHost | Get-Random) | Out-Null
            Start-VM -VM $vm.Name -Confirm:$false -RunAsync | Out-Null
        }
    }
}
