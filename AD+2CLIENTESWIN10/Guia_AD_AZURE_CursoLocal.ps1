# ===== Crear DC =====
az vm create `
  --resource-group 10969-AD `
  --name srv2022 `
  --image MicrosoftWindowsServer:WindowsServer:2022-datacenter:latest `
  --admin-username azureadmin `
  --admin-password Cosas3891610 `
  --size Standard_B2s `
  --vnet-name srv2022-vnet `
  --subnet default `
  --nsg-rule RDP `
  --public-ip-sku Standard `
  --private-ip-address 10.0.0.4 `
  --output table

az network vnet update `
  --name srv2022-vnet `
  --resource-group 10969-AD `
  --dns-servers 10.0.0.4

# ===== En srv2022 - PowerShell como admin =====
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Install-ADDSForest `
  -DomainName "curso.local" `
  -DomainNetbiosName "CURSO" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "Cotas3891610" -AsPlainText -Force) `
  -InstallDNS `
  -Force

# ===== Crear Clientes =====
az vm create `
  --resource-group 10969-AD `
  --name clienteW10-1 `
  --image MicrosoftWindowsDesktop:windows-10:win10-22h2-pro:latest `
  --admin-username azureadmin `
  --admin-password Cotas3891610 `
  --size Standard_B2s `
  --vnet-name srv2022-vnet `
  --subnet default `
  --nsg-rule RDP `
  --private-ip-address 10.0.0.10 `
  --public-ip-address "" `
  --output table

az vm create `
  --resource-group 10969-AD `
  --name clienteW10-2 `
  --image MicrosoftWindowsDesktop:windows-10:win10-22h2-pro:latest `
  --admin-username azureadmin `
  --admin-password Cotas3891610 `
  --size Standard_B2s `
  --vnet-name srv2022-vnet `
  --subnet default `
  --nsg-rule RDP `
  --private-ip-address 10.0.0.11 `
  --public-ip-address "" `
  --output table

# ===== En cada cliente Windows 10 (como admin local) =====
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.0.0.4

Add-Computer -DomainName "curso.local" -Credential curso\azureadmin -Force -Restart
