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
$rulea = New-AzureRmLoadBalancerRuleConfig -Name 'ProdctionLBrule1' -Protocol Tcp `
  -Probe $probe -FrontendPort 80 -BackendPort 80 `
  -FrontendIpConfiguration $feip -BackendAddressPool $bePoolate
$ruleb = New-AzureRmLoadBalancerRuleConfig -Name 'ProdctionLBrule2' -Protocol Tcp `
  -Probe $probe -FrontendPort 443 -BackendPort 443 `
  -FrontendIpConfiguration $feip -BackendAddressPool $bePoolate
 $rulec = New-AzureRmLoadBalancerRuleConfig -Name 'LB8088' -Protocol Tcp `
  -Probe $probe -FrontendPort 8088 -BackendPort 8088 `
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
  -Probe $probe -LoadBalancingRule $rulea,$ruleb,$rulec -InboundNatRule $natrule1,$natrule2,$natrule3

# Create a network security group rule for port 3389.
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleRDP' -Description 'Allow RDP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389

# Create a network security group rule for port 80.
$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name 'myNetworkSecurityGroupRuleHTTP' -Description 'Allow HTTP' `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 1010 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
-Name 'myNetworkSecurityGroup' -SecurityRules $rule1,$rule2

# Create three virtual network cards and associate with public IP address and NSG.
$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'PRODNLB1N1ip' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule1 -Subnet $vnet.Subnets[0]

$nicVM2 = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'PRODNLB1N2ip' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule2 -Subnet $vnet.Subnets[0]

$nicVM3 = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'PRODNLB1N3ip' -LoadBalancerBackendAddressPool $bepool -NetworkSecurityGroup $nsg `
  -LoadBalancerInboundNatRule $natrule3 -Subnet $vnet.Subnets[0]

# Create an availability set.
$as = New-AzureRmAvailabilitySet -ResourceGroupName $rgName -Location $location `
  -Name 'MyAvailabilitySet' -Sku Aligned -PlatformFaultDomainCount 3 -PlatformUpdateDomainCount 3

# Create three virtual machines.