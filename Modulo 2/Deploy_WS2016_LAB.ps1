
# ========================
# CONFIGURACIÓN INICIAL
# ========================
$resourceGroup = "RG-WS2016LAB"
$location = "East US 2"
$vnetName = "VNET-WS2016LAB"
$subnetName = "default"
$addressPrefix = "10.30.0.0/24"
$subnetPrefix = "10.30.0.0/24"
$vmSize = "Standard_A1_v2"
$vmName = "SRVDC2016"
$privateIp = "10.30.0.4"
$adminUser = "azureuser"
$adminPassword = ConvertTo-SecureString "Cosas3891610" -AsPlainText -Force

# ========================
# CREAR GRUPO DE RECURSOS
# ========================
New-AzResourceGroup -Name $resourceGroup -Location $location

# ========================
# CREAR VNET Y SUBRED
# ========================
$vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup -Location $location `
    -AddressPrefix $addressPrefix
Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPrefix -VirtualNetwork $vnet
$vnet | Set-AzVirtualNetwork

# ⚠️ Recargar VNET
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

# ========================
# CREAR IP PÚBLICA
# ========================
$publicIp = New-AzPublicIpAddress -Name "$vmName-ip" -ResourceGroupName $resourceGroup `
    -Location $location -AllocationMethod Dynamic -Sku Basic

# ========================
# CREAR NSG Y REGLA RDP
# ========================
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name "$vmName-nsg"
$nsg | Add-AzNetworkSecurityRuleConfig -Name "Allow-RDP" -Priority 1000 -Direction Inbound `
    -Access Allow -Protocol Tcp -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389 | Set-AzNetworkSecurityGroup

# ========================
# NIC CON IP FIJA
# ========================
$nic = New-AzNetworkInterface -Name "$vmName-nic" `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -SubnetId $subnet.Id `
    -PrivateIpAddress $privateIp `
    -PublicIpAddressId $publicIp.Id `
    -NetworkSecurityGroupId $nsg.Id

# ========================
# CONFIGURAR Y CREAR VM
# ========================
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName `
        -Credential (New-Object PSCredential($adminUser, $adminPassword)) -ProvisionVMAgent -EnableAutoUpdate |
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" `
        -Skus "2016-Datacenter" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nic.Id

New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig
