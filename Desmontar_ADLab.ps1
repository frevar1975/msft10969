# =============================================
# SCRIPT PARA DESMONTAR ENTORNO DE PRUEBAS AD
# =============================================
$ErrorActionPreference = "Stop"

# Parámetros iniciales
$resourceGroups = @("RG-WS2016LAB", "RG-WS2022LAB")

foreach ($rg in $resourceGroups) {
    Write-Host "`nEliminando grupo de recursos: $rg`n"
    Remove-AzResourceGroup -Name $rg -Force -AsJob
}

Write-Host "`nSe han enviado las órdenes de eliminación de los grupos de recursos. Verifica el portal para seguimiento.`n"
