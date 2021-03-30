#Provide the subscription Id
$subscriptionId = '480c56b2-d622-4ad8-946c-aa0d8c25467a'

#Provide the name of your resource group
$resourceGroupName ='ssk6'

$LOC="West US "

$SUBNETNAME=$RG+"West-Subnet-1"
#Provide the name of the snapshot that will be used to create OS disk
$snapshotName = 'test6-os'

#Provide the name of the OS disk that will be created using the snapshot
$osDiskName = 'test6-0s-2221'

#Provide the name of an existing virtual network where virtual machine will be created
$virtualNetworkName = 't6vnet'

#Provide the name of the virtual machine
$virtualMachineName = 'test6'

#Provide the size of the virtual machine
#e.g. Standard_D2
#Get all the vm sizes in a region using below script:
#e.g. Get-AzureRmVMSize -Location westus
$virtualMachineSize = 'Standard_D2'

#Set the context to the subscription Id where Managed Disk will be created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

$snapshot = Get-AzureRmSnapshot - $resourceGroupName -SnapshotName $snapshotName
 
$diskConfig = New-AzureRmDiskConfig -LoResourceGroupNamecation $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy
 
$disk = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $osDiskName

#Initialize virtual machine configuration
$VirtualMachine = New-AzureRmVMConfig -VMName $virtualMachineName -VMSize $virtualMachineSize

#Use the Managed Disk Resource Id to attach it to the virtual machine. Please change the OS type to linux if OS disk has linux OS
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -ManagedDiskId $disk.Id -CreateOption Attach -windows

#Create a public IP for the VM
$publicIp = New-AzureRmPublicIpAddress -Name ($VirtualMachineName.ToLower()+'_ip') -ResourceGroupName $resourceGroupName -Location $snapshot.Location -AllocationMethod Dynamic

#NEW virtual network where virtual machine will be hosted
$vnet = NEW-AzureRmVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $LOC -AddressPrefix 192.168.200.0/28


$nsgrule = New-AzureRmNetworkSecurityRuleConfig -Name RDP -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange 3389
$nsgrule = New-AzureRmNetworkSecurityRuleConfig -Name HTTP -Description "Allow HTTP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange 80

Add-AzureRmVirtualNetworkSubnetConfig -Name $SUBNETNAME -VirtualNetwork $vnet -AddressPrefix 192.168.200.0/28 -NetworkSecurityGroup $nsg

$vnet=Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

$subnet =Get-AzureRmVirtualNetworkSubnetConfig -Name $SUBNETNAME -VirtualNetwork $vnet

$subnet.id 
# Create NIC in the first subnet of the virtual network
$nic = New-AzureRmNetworkInterface -Name ($VirtualMachineName.ToLower()+'_nic') -ResourceGroupName $resourceGroupName -Location $snapshot.Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $nic.Id

#Create the virtual machine with Managed Disk
New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $resourceGroupName -Location $snapshot.Location