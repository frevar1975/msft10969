
# ============================
# PROMOCIÓN A CONTROLADOR DE DOMINIO - WS2016
# ============================

# Variables
$domainName = "contoso.local"
$netbiosName = "CONTOSO"
$safeModePassword = ConvertTo-SecureString "Cosas3891610" -AsPlainText -Force

# Instalar el rol de AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promover como primer DC del bosque contoso.local
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -SafeModeAdministratorPassword $safeModePassword `
    -InstallDNS `
    -Force
