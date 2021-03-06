# Description: Export to CSV all VMs that are Powered on and are Windows
# Add in the PowerCLI CMDLET
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
# Connect to the vCenter using passthru
Connect-VIServer 10.0.11.179

$ErrorView="CategoryView" 
$results =@()

$DontTry = (Get-Content "C:\Documents and Settings\joseph.kordish.da\Desktop\PoweredOff_Or_Not_Windows.csv")
$vms = (Get-VM -Location "New Prod-Test" | Where-Object {$_.PowerState -eq "PoweredOn" -and $_.Guest.OSFullName -match "Win*"})


foreach($vm in $vms){
    Clear-Variable row
    if($DontTry -notcontains $vm.Name){
        $row = "" | Select Name, IP, VLAN, OperatingSystem, SiteCode, Host, Cluster
        try{
            $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$vm.Guest.HostName)
            $regKey = $reg.OpenSubKey("SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\")
            $row.SiteCode = $regKey.GetValue("DynamicSiteName")}
        catch{
            $Error[0].Exception.Message.split(":")[1].replace("`"","").trim()
            $row.SiteCode = $Error[0].Exception.Message.split(":")[1].replace("`"","").trim()}
        $row.Name = $vm.Name
        $row.Host = $vm.VMHost.Name
        $row.OperatingSystem = $vm.Guest.OSFullName
        $row.Cluster = (Get-Cluster -VM $vm.Name)
        $row.IP = ($vm.Guest | ForEach-Object {$_.IPAddress}) -join ","  
        $row.VLAN = ($vm | Get-NetworkAdapter | ForEach-Object {$_.NetworkName}) -join ","
        $results += $row
        }
        else{ Write-Host "Skipping:"$vm.Name
    }
}
$results | export-csv c:\PoweredOn_And_Windows_Export_Data_v2.csv -UseCulture -NoTypeInformation
#$results | Out-GridView
