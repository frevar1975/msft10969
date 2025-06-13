Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
$securePwd = ConvertTo-SecureString 'Cosas3891610' -AsPlainText -Force
Install-ADDSForest -DomainName 'local.curso.com' -DomainNetbiosName 'CURSO' `
  -SafeModeAdministratorPassword $securePwd -InstallDNS -Force
Restart-Computer -Force
