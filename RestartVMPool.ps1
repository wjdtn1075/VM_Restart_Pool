Prod by Jeongsoo.Kim@goodus.com
Updated 2023-04-06
Version 0.5

## Importing Module
Get-Module -Name VMware.VimAutomation.Core
Get-Module -Name VMware.VumAutomation
Get-Module -Name VMware.VimAutomation.HorizonView

Write-Host "Import Module: VMware.VimAutomation.HorizonView"
Import-Module -Name VMware.VimAutomation.HorizonView

Get-Module -ListAvailable 'VMware.Hv.Helper' | Import-Module

Write-Host "Import Module: VMware.VimAutomation.Core"
Import-Module -Name VMware.VimAutomation.Core
Write-Host "Import Complete"

Write-Host "Import Module: VMware.Hv.Helper"
Import-Module -Name VMware.Hv.Helper
Write-Host "Import Complete"

## Getting HVDesktop Status (whether it is availabe or unavailabe)

## Horizon Connection Server info
$User = "horizonsvc"
$Password = "VMware1!"
$poolname = "wind10-Dedi-Auto" " 
$Domainadd = "kjs.nsx"

## vCenter info
$vcuser = "administrator@vsphere.local"
$vcpasswd = "VMware1!"

## Connect Horizon Connection Server
Write-Host "Connect to connection server"

$connSvr = Connect-HVServer -Server 'cs01' -User $User -Password $Password -Domain $Domainadd
$viewAPI = $connSvr.ExtensionData

## vCenter 접속

Write-Output "Connect to vCenter"
$viConn = Connect-VIServer -Server 'vc01.kjs.nsx' -User $vcuser -Password $vcpasswd
Write-Output "Connect to vCenter complete"

## Get pool info
$poolinfo =  Get-HVPool -PoolName $poolname | select -expandproperty Base | select-object Name
#$repool = 
foreach ($pool in $poolinfo) {
	Write-Host "Restarting virtual machines in pool $($pool.Name)"
	#$vmlist = Get-HVDesktop -Pool $pool
	$vmlist = Get-HVMachine -pool $poolname | select -expandproperty Base | Select Name, BasicState
	foreach ($vm in $vmlist) {
	if($vm.BasicState -eq 'PROVISIONING_ERROR' -or`
	   $vm.BasicState -eq 'ERROR' -or`
	   $vm.BasicState -eq 'AGENT_UNREACHABLE' -or`
	   $vm.BasicState -eq 'AGENT_ERR_STARTUP_IN_PROGRESS' -or`
	   $vm.BasicState -eq 'AGENT_ERR_DISABLED' -or`
	   $vm.BasicState -eq 'AGENT_ERR_INVALID_IP' -or`
	   $vm.BasicState -eq 'AGENT_ERR_NEED_REBOOT' -or`
	   $vm.BasicState -eq 'AGENT_ERR_PROTOCOL_FAILURE' -or`
	   $vm.BasicState -eq 'AGENT_ERR_DOMAIN_FAILURE' -or`
	   $vm.BasicState -eq 'AGENT_CONFIG_ERROR' -or`
	   $vm.BasicState -eq 'UNKNOWN' )
	{
		$msg = [string]::Format("Unavailable VM : {0}, Restart VM - Force", $vm.Name)
		Write-Host $msg -Foregroundcolor Red
		Restart-VM -VM $vm.Name -RunAsync -Confirm:$false
	}
	elseif($vm.BasicState -eq 'CONNECTED')
	{
		$msg = [string]::Format("Connected VM   : {0}, Bypass", $vm.Name)
		Write-Host $msg -Foregroundcolor Gray
	}	
	else
	{
		$msg = [string]::Format("Available VM   : {0}, Restart Guest OS", $vm.Name)
		Write-Host $msg -Foregroundcolor Green
		Get-VM $vm.Name | Where {$_.PowerState -eq "PoweredOn"} | Restart-VMGuest -Confirm:$false
	}
	}
}

#>
# 연결 종
Disconnect-VIServer $viConn -Confirm:$false
Disconnect-HVServer $connSvr -Confirm:$false

