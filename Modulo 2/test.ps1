<#
.SYNOPSIS
  Exercise 2 completo: desde cero en Azure, crea un DC writable y un RODC, y configura la Password Replication Policy.

.PARAMETER Location
  Región de Azure donde se crearán todos los recursos.

.PARAMETER RG
  Nombre del Resource Group.

.PARAMETER VNet
  Nombre de la Virtual Network.

.PARAMETER Subnet
  Nombre de la Subnet.

.PARAMETER DcVM
  Nombre de la VM que será el DC writable.

.PARAMETER RodcVM
  Nombre de la VM que será el RODC.

.PARAMETER AdminUser
  Usuario administrador de las VMs.

.PARAMETER AdminPass
  Contraseña del usuario administrador.

.PARAMETER Allowed
  Grupos o usuarios permitidos en la PRP del RODC.

.PARAMETER Denied
  Grupos o usuarios denegados en la PRP del RODC.
#>

param(
  [string]   $Location   = "eastus2",
  [string]   $RG         = "Demo-AD-RG",
  [string]   $VNet       = "Demo-AD-VNet",
  [string]   $Subnet     = "Demo-DC-Subnet",
  [string]   $DcVM       = "DC2022",
  [string]   $RodcVM     = "RODC01",
  [string]   $AdminUser  = "azureadmin",
  [string]   $AdminPass  = "P@ssw0rd1234!",
  [string[]] $Allowed    = @("CONTOSO\FinanceUsers","CONTOSO\ITAdmins"),
  [string[]] $Denied     = @("CONTOSO\HRUsers")
)

# Requiere Az module instalado y Connect-AzAccount previo
if (-not (Get-AzContext)) {
  Write-Host "Por favor conéctate primero con Connect-AzAccount" -ForegroundColor Yellow
  return
}

# 1) Crear Resource Group y VNet/Subnet
Write-Host "1) Creando RG '$RG' y red virtual..." -ForegroundColor Cyan
New-AzResourceGroup -Name $RG -Location $Location | Out-Null
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $RG `
  -Name $VNet `
  -Location $Location `
  -AddressPrefix "10.20.0.0/16"
$vnet | Add-AzVirtualNetworkSubnetConfig -Name $Subnet -AddressPrefix "10.20.1.0/24" | Set-AzVirtualNetwork

# Helper para desplegar VMs con IP estática y NSG
function New-ADVm {
  param($Name, $IP)

  Write-Host "`n=> Desplegando VM $Name con IP $IP..." -ForegroundColor Cyan

  # Public IP
  $pip = New-AzPublicIpAddress `
    -ResourceGroupName $RG `
    -Name "$Name-pip" `
    -Location $Location `
    -AllocationMethod Static `
    -Sku Standard

  # NSG con regla RDP
  $rule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-RDP" `
    -Description "Allow RDP" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389

  $nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $RG `
    -Location $Location `
    -Name "NSG-$Name" `
    -SecurityRules $rule

  # NIC
  $subnetObj = $vnet.Subnets | Where-Object Name -EQ $Subnet
  $nic = New-AzNetworkInterface `
    -ResourceGroupName $RG `
    -Name "$Name-nic" `
    -Location $Location `
    -SubnetId $subnetObj.Id `
    -PrivateIpAddress $IP `
    -NetworkSecurityGroupId $nsg.Id `
    -PublicIpAddressId $pip.Id

  # Crear VM
  $cred = New-Object PSCredential($AdminUser,(ConvertTo-SecureString $AdminPass -AsPlainText -Force))
  New-AzVm `
    -ResourceGroupName $RG `
    -Name $Name `
    -Location $Location `
    -NetworkInterfaceId $nic.Id `
    -Image "MicrosoftWindowsServer:windowsserver:2022-datacenter:latest" `
    -Size "Standard_D2s_v3" `
    -Credential $cred `
    -NoWait
}

# 2) Desplegar el DC writable
New-ADVm -Name $DcVM   -IP "10.20.1.10"

# 3) Desplegar el RODC
New-ADVm -Name $RodcVM -IP "10.20.1.11"

# 4) Esperar a que ambas VMs estén aprovisionadas
Write-Host "`nEsperando a que las VMs estén listas..." -ForegroundColor Cyan
do {
  $s1 = (Get-AzVm -ResourceGroupName $RG -Name $DcVM).ProvisioningState
  $s2 = (Get-AzVm -ResourceGroupName $RG -Name $RodcVM).ProvisioningState
  Start-Sleep -Seconds 5
} until ($s1 -eq "Succeeded" -and $s2 -eq "Succeeded")

# 5) Instalar y promover el DCWritable
Write-Host "`n5) Instalando AD DS en $DcVM y creando bosque contoso.local..." -ForegroundColor Cyan
Invoke-AzVmRunCommand `
  -ResourceGroupName $RG `
  -Name $DcVM `
  -CommandId 'RunPowerShellScript' `
  -ScriptString @"
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
\$pwd = ConvertTo-SecureString '$AdminPass' -AsPlainText -Force
Install-ADDSForest -DomainName 'contoso.local' -DomainNetbiosName 'CONTOSO' -SafeModeAdministratorPassword \$pwd -InstallDNS -Force
Restart-Computer -Force
"@

# Dar tiempo al reinicio del DC
Write-Host "   Esperando 60s por el reinicio de $DcVM..." -ForegroundColor Cyan
Start-Sleep -Seconds 60

# 6) Pre-staging de la cuenta RODC en el DCWritable
Write-Host "`n6) Haciendo pre‐stage de RODC '$RodcVM' en DCWritable..." -ForegroundColor Cyan
Invoke-AzVmRunCommand `
  -ResourceGroupName $RG `
  -Name $DcVM `
  -CommandId 'RunPowerShellScript' `
  -ScriptString @"
Import-Module ActiveDirectory
\$pwd = ConvertTo-SecureString '$AdminPass' -AsPlainText -Force
Add-ADDSReadOnlyDomainControllerAccount -DomainControllerAccountName '$RodcVM' -DomainName 'contoso.local' -SafeModeAdministratorPassword \$pwd
"@

# 7) Promover el RODC
Write-Host "`n7) Promoviendo '$RodcVM' como RODC..." -ForegroundColor Cyan
Invoke-AzVmRunCommand `
  -ResourceGroupName $RG `
  -Name $RodcVM `
  -CommandId 'RunPowerShellScript' `
  -ScriptString @"
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
\$cred = Get-Credential -UserName 'CONTOSO\$RodcVM`$' -Message 'Ingrese pwd DSRM para pre-staged RODC'
Install-ADDSDomainController -ReadOnlyReplica -Credential \$cred -DomainName 'contoso.local' -SiteName 'Default-First-Site-Name' -DatabasePath 'D:\NTDS' -LogPath 'D:\NTDS\Logs' -SysvolPath 'D:\SYSVOL' -SafeModeAdministratorPassword \$cred.Password -InstallDNS:\$false -Force
Restart-Computer -Force
"@

# Esperar reinicio del RODC
Write-Host "   Esperando 60s por el reinicio de $RodcVM..." -ForegroundColor Cyan
Start-Sleep -Seconds 60

# 8) Configurar la Password Replication Policy
Write-Host "`n8) Configurando PRP en '$RodcVM'..." -ForegroundColor Cyan
$allowedList = $Allowed -join "','"
$deniedList  = $Denied  -join "','"
Invoke-AzVmRunCommand `
  -ResourceGroupName $RG `
  -Name $DcVM `
  -CommandId 'RunPowerShellScript' `
  -ScriptString @"
Import-Module ActiveDirectory
Set-ADDomainControllerReadOnlyReplicaPasswordReplicationPolicy -Identity '$RodcVM' -AllowedList @('$allowedList') -DeniedList @('$deniedList')
Write-Host 'Allowed:' (Get-ADDomainControllerPasswordReplicationPolicy -Identity '$RodcVM').AllowedList
Write-Host 'Denied :' (Get-ADDomainControllerPasswordReplicationPolicy -Identity '$RodcVM').DeniedList
"@

Write-Host "`nExercise 2 completado." -ForegroundColor Green
