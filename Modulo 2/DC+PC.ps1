# ========================
# CONFIGURACIÓN INICIAL
# ========================
$resourceGroup = "RG-10969"
$location = "East US 2"
$vnetName = "DominioVNet"
$subnetName = "default"
$addressPrefix = "10.10.0.0/24"
$subnetPrefix = "10.10.0.0/24"
$vmSizeServer = "Standard_B2ms"  # Para SRV01 (Windows Server 2022)
$vmSizeWin10 = "Standard_B2s"    # Para Windows 10 (más liviano)
$adminUser = "azureuser"
$adminPassword = ConvertTo-SecureString "Cosas3891610" -AsPlainText -Force

# Lista de VMs
$vms = @(
    @{ Name = "SRV01"; PrivateIP = "10.10.0.4"; Tipo = "Server" },
    @{ Name = "WIN10-CLIENT"; PrivateIP = "10.10.0.5"; Tipo = "Win10" }
)

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

# ⚠️ Recargar VNET desde Azure
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

# ========================
# CREAR CADA VM
# ========================
foreach ($vm in $vms) {
    $vmName = $vm.Name
    $privateIp = $vm.PrivateIP
    $tipo = $vm.Tipo

    Write-Host "`nCreando VM: $vmName con IP: $privateIp ($tipo)`n"

    # IP pública
    $publicIp = New-AzPublicIpAddress -Name "$vmName-ip" -ResourceGroupName $resourceGroup `
        -Location $location -AllocationMethod Dynamic -Sku Basic

    # NSG con regla RDP
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name "$vmName-nsg"
    $nsg | Add-AzNetworkSecurityRuleConfig -Name "Allow-RDP" -Priority 1000 -Direction Inbound `
        -Access Allow -Protocol Tcp -SourceAddressPrefix * -SourcePortRange * `
        -DestinationAddressPrefix * -DestinationPortRange 3389 | Set-AzNetworkSecurityGroup

    # NIC
    $nic = New-AzNetworkInterface -Name "$vmName-nic" `
        -ResourceGroupName $resourceGroup `
        -Location $location `
        -SubnetId $subnet.Id `
        -PrivateIpAddress $privateIp `
        -PublicIpAddressId $publicIp.Id `
        -NetworkSecurityGroupId $nsg.Id

    # Configurar VM según tipo
    if ($tipo -eq "Server") {
        $vmSize = $vmSizeServer
        $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
            Set-AzVMOperatingSystem -Windows -ComputerName $vmName `
                -Credential (New-Object PSCredential($adminUser, $adminPassword)) -ProvisionVMAgent -EnableAutoUpdate |
            Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" `
                -Skus "2022-datacenter" -Version "latest" |
            Add-AzVMNetworkInterface -Id $nic.Id
    }
    elseif ($tipo -eq "Win10") {
        $vmSize = $vmSizeWin10
        $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
            Set-AzVMOperatingSystem -Windows -ComputerName $vmName `
                -Credential (New-Object PSCredential($adminUser, $adminPassword)) -ProvisionVMAgent -EnableAutoUpdate |
            Set-AzVMSourceImage -PublisherName "MicrosoftWindowsDesktop" -Offer "windows-10" `
                -Skus "win10-21h2-pro" -Version "latest" |
            Add-AzVMNetworkInterface -Id $nic.Id
    }

    # Crear VM
    New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig
}
