# ========================
# PARÁMETROS BASE
# ========================
$resourceGroup = "RG-10969"
$location = "East US 2"
$vnetName = "DominioVNet"
$subnetName = "default"
$adminUser = "azureuser"
$adminPassword = ConvertTo-SecureString "Cosas3891610" -AsPlainText -Force

# ========================
# RECUPERAR VNET Y SUBNET EXISTENTE
# ========================
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

# ========================
# CREAR VM WIN10-KIOSK01
# ========================
$vmNameKiosk = "WIN10-KIOSK01"
$privateIpKiosk = "10.10.0.6"
$vmSizeKiosk = "Standard_A1_v2"  # Fuera de la familia B para evitar el problema de cuota

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
