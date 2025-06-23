# ========================
# CONFIGURACIÓN INICIAL
# ========================
$resourceGroup = "RG-10969"
$location = "East US 2"
$vnetName = "DominioVNet"
$subnetName = "default"
$adminUser = "azureuser"
$adminPassword = ConvertTo-SecureString "Cosas3891610" -AsPlainText -Force

# Tamaños de VM
$vmSizeClient = "Standard_B2s"  # 2 vCPU, 4 GB RAM
$vmSizeKiosk = "Standard_B1ls"  # 1 vCPU, 0.5 GB RAM (suficiente para kiosko)

# ========================
# RECUPERAR VNET Y SUBNET
# ========================
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

# ========================
# CREAR VM WIN10-CLIENT02
# ========================

$vmNameClient = "WIN10-CLIENT02"
$privateIpClient = "10.10.0.5"

# IP pública
$publicIpClient = New-AzPublicIpAddress -Name "$vmNameClient-ip" -ResourceGroupName $resourceGroup `
    -Location $location -AllocationMethod Dynamic -Sku Basic

# NSG con regla RDP
$nsgClient = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name "$vmNameClient-nsg"
$nsgClient | Add-AzNetworkSecurityRuleConfig -Name "Allow-RDP" -Priority 1000 -Direction Inbound `
    -Access Allow -Protocol Tcp -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389 | Set-AzNetworkSecurityGroup

# NIC
$nicClient = New-AzNetworkInterface -Name "$vmNameClient-nic" `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -SubnetId $subnet.Id `
    -PrivateIpAddress $privateIpClient `
    -PublicIpAddressId $publicIpClient.Id `
    -NetworkSecurityGroupId $nsgClient.Id

# Configuración de la VM Cliente
$vmConfigClient = New-AzVMConfig -VMName $vmNameClient -VMSize $vmSizeClient |
    Set-AzVMOperatingSystem -Windows -ComputerName $vmNameClient `
        -Credential (New-Object PSCredential($adminUser, $adminPassword)) -ProvisionVMAgent -EnableAutoUpdate |
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsDesktop" -Offer "windows-10" `
        -Skus "win10-21h2-pro" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nicClient.Id

# Crear la VM Cliente
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfigClient

# ========================
# CREAR VM WIN10-KIOSK01
# ========================

$vmNameKiosk = "WIN10-KIOSK01"
$privateIpKiosk = "10.10.0.6"

# IP pública
$publicIpKiosk = New-AzPublicIpAddress -Name "$vmNameKiosk-ip" -ResourceGroupName $resourceGroup `
    -Location $location -AllocationMethod Dynamic -Sku Basic

# NSG con regla RDP
$nsgKiosk = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name "$vmNameKiosk-nsg"
$nsgKiosk | Add-AzNetworkSecurityRuleConfig -Name "Allow-RDP" -Priority 1000 -Direction Inbound `
    -Access Allow -Protocol Tcp -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389 | Set-AzNetworkSecurityGroup

# NIC
$nicKiosk = New-AzNetworkInterface -Name "$vmNameKiosk-nic" `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -SubnetId $subnet.Id `
    -PrivateIpAddress $privateIpKiosk `
    -PublicIpAddressId $publicIpKiosk.Id `
    -NetworkSecurityGroupId $nsgKiosk.Id

# Configuración de la VM KIOSKO
$vmConfigKiosk = New-AzVMConfig -VMName $vmNameKiosk -VMSize $vmSizeKiosk |
    Set-AzVMOperatingSystem -Windows -ComputerName $vmNameKiosk `
        -Credential (New-Object PSCredential($adminUser, $adminPassword)) -ProvisionVMAgent -EnableAutoUpdate |
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsDesktop" -Offer "windows-10" `
        -Skus "win10-21h2-pro" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nicKiosk.Id

# Crear la VM KIOSKO
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfigKiosk
