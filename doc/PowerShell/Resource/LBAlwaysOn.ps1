# Variables for common values
$rgName='Production'
$location='North Central US'

# Create user object
$cred = Get-Credential -Message 'Enter a username and password for the virtual machine.'

# Create a resource group.
New-AzureRmResourceGroup -Name $rgName -Location $location

# Create a virtual network.
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'Subnet-1' -AddressPrefix 192.168.3.0/24

$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name 'rtresponse-Vnet' `
  -AddressPrefix 192.168.0.0/16 -Location $location -Subnet $subnet

# Create a public IP address.
$publicIp = New-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name 'Prodnlb1n1' `
  -Location $location -AllocationMethod Dynamic

# Create a front-end IP configuration for the website.
$feip = New-AzureRmLoadBalancerFrontendIpConfig -Name 'LoadBalancerFrontEnd' -PublicIpAddress $publicIp

# Create the back-end address pool.
$bepool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name 'ProductionWEB'

# Creates a load balancer probe on port 80.
$probe = New-AzureRmLoadBalancerProbeConfig -Name 'ProductHelthProbe' -Protocol Http -Port 80 `
  -RequestPath / -IntervalInSeconds 5 -ProbeCount 5

# Cres a load balancer rule for port 80.
$rule = New-AzureRmLoadBalancerRuleConfig -Name 'myLoadBalancerRuleWeb' -Protocol Tcp `
  -Probe $probe -FrontendPort 80 -BackendPort 80 `
  -FrontendIpConfiguration $feip -BackendAddressPool $bePoolate
$rule = New-AzureRmLoadBalancerRuleConfig -Name 'myLoadBalancerRuleWeb' -Protocol Tcp `
  -Probe $probe -FrontendPort 443 -BackendPort 443 `
  -FrontendIpConfiguration $feip -BackendAddressPool $bePoolate
 $rule = New-AzureRmLoadBalancerRuleConfig -Name 'myLoadBalancerRuleWeb' -Protocol Tcp `
  -Probe $probe -FrontendPort 80 -BackendPort 443 `
  -FrontendIpConfiguration $feip -BackendAddressPool $bePoolate

# Create three NAT rules for port 3389.
$natrule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name 'myLoadBalancerRDP1' -FrontendIpConfiguration $feip `
  -Protocol tcp -FrontendPort 4221 -BackendPort 3389

$natrule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name 'myLoadBalancerRDP2' -FrontendIpConfiguration $feip `
  -Protocol tcp -FrontendPort 4222 -BackendPort 3389

$natrule3 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name 'myLoadBalancerRDP3' -FrontendIpConfiguration $feip `
  -Protocol tcp -FrontendPort 4223 -BackendPort 3389

# Create a load balancer.
$lb = New-AzureRmLoadBalancer -ResourceGroupName $rgName -Name 'MyLoadBalancer' -Location $location `
  -FrontendIpConfiguration $feip -BackendAddressPool $bepool `
  -Probe $probe -LoadBalancingRule $rule -InboundNatRule $natrule1,$natrule2,$natrule3

# Create a network security group rule for port 3389.
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleRDP' -Description 'Allow RDP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389

# Create a network security group rule for port 80.
$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleHTTP' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 2000 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
-Name 'myNetworkSecurityGroup' -SecurityRules $rule1,$rule2

# Create three virtual network cards and associate with public IP address and NSG.
$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic1' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule1 -Subnet $vnet.Subnets[0]

$nicVM2 = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic2' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule2 -Subnet $vnet.Subnets[0]

$nicVM3 = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic3' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule3 -Subnet $vnet.Subnets[0]

# Create an availability set.
$as = New-AzureRmAvailabilitySet -ResourceGroupName $rgName -Location $location `
  -Name 'MyAvailabilitySet' -Sku Aligned -PlatformFaultDomainCount 3 -PlatformUpdateDomainCount 3

# Create three virtual machines.

# ############## VM1 ###############

































# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName 'myVM1' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName 'myVM1' -Credential $cred | `
  Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nicVM1.Id

# Create a virtual machine
$vm1 = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# ############## VM2 ###############

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName 'myVM2' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName 'myVM2' -Credential $cred | `
  Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nicVM2.Id

# Create a virtual machine
$vm2 = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# ############## VM3 ###############

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName 'myVM3' -VMSize Standard_DS2 -AvailabilitySetId $as.Id | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName 'myVM3' -Credential $cred | `
  Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nicVM3.Id

# Create a virtual machine
$vm3 = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vmConfig