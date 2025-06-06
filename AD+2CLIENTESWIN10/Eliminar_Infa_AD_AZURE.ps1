# ===== ELIMINAR CLIENTES =====
az vm delete --name clienteW10-1 --resource-group 10969-AD --yes --no-wait
az vm delete --name clienteW10-2 --resource-group 10969-AD --yes --no-wait

# ===== ELIMINAR CONTROLADOR DE DOMINIO =====
az vm delete --name srv2022 --resource-group 10969-AD --yes --no-wait

# ===== ELIMINAR IPs públicas si quedan liberadas =====
az network public-ip delete --name srv2022-ip --resource-group 10969-AD --yes
az network public-ip delete --name clienteW10-1-ip --resource-group 10969-AD --yes
az network public-ip delete --name clienteW10-2-ip --resource-group 10969-AD --yes

# ===== ELIMINAR RED, NICs y DISCOS (si se desea) =====
# az group delete --name 10969-AD --yes --no-wait