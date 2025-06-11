
# ========================
# LIMPIEZA DE RECURSOS
# ========================
$resourceGroup = "RG-10969"

# Confirmar antes de borrar
Write-Host "Este script eliminará todo el grupo de recursos: $resourceGroup"
$confirm = Read-Host "¿Deseas continuar? (sí/no)"
if ($confirm -ne "sí") {
    Write-Host "Operación cancelada por el usuario."
    exit
}

# Eliminar el grupo de recursos completo (incluye VMs, VNET, NICs, IPs, etc.)
Remove-AzResourceGroup -Name $resourceGroup -Force -AsJob

Write-Host "`nEliminación iniciada en segundo plano. Puedes revisar el progreso con Get-Job y Receive-Job."
