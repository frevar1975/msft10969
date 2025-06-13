
# ============================
# PROMOCIÓN A CONTROLADOR DE DOMINIO
# ============================

# Variables
$domainName = "lab.local"
$netbiosName = "LAB"
$adminUser = "azureuser"
$adminPassword = ConvertTo-SecureString "Cosas3891610" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($adminUser, $adminPassword)

# 1. Instalar el rol de AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# 2. Crear nueva clave KDS (requerida para gMSA)
Add-KdsRootKey -EffectiveImmediately

# 3. Promover como primer controlador de dominio en nuevo bosque
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -SafeModeAdministratorPassword $adminPassword `
    -InstallDns `
    -Force:$true
