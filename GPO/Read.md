Aquí tienes un **guion completo de demo**, partiendo de un Active Directory “limpio” (sin OUs ni GPOs), que podrás correr paso a paso en PowerShell para una sesión de unos **30 min**. Incluye comentarios para que lo puedas copiar/pegar literalmente.

---

## 0️⃣ Preparativos

* Debes estar en un **DC Windows Server 2022** con el módulo **GroupPolicy** y el rol **Active Directory** instalado.
* Abre PowerShell **como Administrador** y ejecuta `Import-Module GroupPolicy`.

---

## 1️⃣ Crear OUs de ejemplo

```powershell
# -------------------------------------------------
# 1) CREAMOS 2 OUs: "Sucursales" y "Finanzas"
# -------------------------------------------------
$rootDN = (Get-ADDomain).DistinguishedName

Write-Host "`n[1] Creando OUs..." -ForegroundColor Cyan
New-ADOrganizationalUnit -Name "Sucursales" -Path $rootDN -ProtectedFromAccidentalDeletion:$false
New-ADOrganizationalUnit -Name "Finanzas"   -Path $rootDN -ProtectedFromAccidentalDeletion:$false
```

---

## 2️⃣ Crear GPOs base (Starter GPOs)

```powershell
# -------------------------------------------------
# 2) CREAMOS 3 GPOs de inicio para distintos edificios
# -------------------------------------------------
Write-Host "`n[2] Creando Starter GPOs..." -ForegroundColor Cyan
$gpos = @("GPO-Sucursales","GPO-Finanzas","GPO-Global")
foreach($g in $gpos) {
    New-GPO -Name $g -Comment "Reglas base para $g" | Out-Null
    Write-Host "  → $g creado"
}
```

---

## 3️⃣ Copiar un GPO para un caso particular

```powershell
# -------------------------------------------------
# 3) COPIAR GPO-Sucursales a GPO-Sucursales-Remota
# -------------------------------------------------
Write-Host "`n[3] Copiando GPO-Sucursales..." -ForegroundColor Cyan
Copy-GPO -SourceName "GPO-Sucursales" -TargetName "GPO-Sucursales-Remota" -Comment "Rama remota"
```

---

## 4️⃣ Añadir una configuración práctica

Deshabilitar puertos USB en todas las “Finanzas”:

```powershell
# -------------------------------------------------
# 4) EDITAR GPO-Finanzas: registro para bloquear USB
# -------------------------------------------------
Write-Host "`n[4] Configurando bloqueo de USB en GPO-Finanzas..." -ForegroundColor Cyan
Set-GPRegistryValue -Name "GPO-Finanzas" `
    -Key "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" `
    -ValueName "Deny_All" -Type DWord -Value 1
```

---

## 5️⃣ Linkear GPOs a las OUs

```powershell
# -------------------------------------------------
# 5) LINKEAR GPOs a OUs
# -------------------------------------------------
Write-Host "`n[5] Vinculando GPOs..." -ForegroundColor Cyan
# GPO-Sucursales-Remota → OU=Sucursales
New-GPLink -Name "GPO-Sucursales-Remota" -Target "OU=Sucursales,$rootDN"

# GPO-Finanzas → OU=Finanzas
New-GPLink -Name "GPO-Finanzas" -Target "OU=Finanzas,$rootDN"
```

---

## 6️⃣ Backup (exportar) y restauración (.cab)

```powershell
# -------------------------------------------------
# 6.1) EXPORTAR todos los GPOs a backups
# -------------------------------------------------
$backupDir = "C:\Demo\GPOBackups"
Write-Host "`n[6.1] Creando backups en $backupDir..." -ForegroundColor Cyan
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Get-GPO -All | ForEach-Object { Backup-GPO -Name $_.DisplayName -Path $backupDir }


```

---

## 7️⃣ Reporte y verificación

```powershell
# -------------------------------------------------
# 7) GENERAR reporte HTML de GPO-Finanzas y abrirlo
# -------------------------------------------------
$reportPath = "C:\Demo\GPO-Finanzas.html"
Write-Host "`n[7] Generando reporte de GPO-Finanzas en $reportPath..." -ForegroundColor Cyan
Get-GPOReport -Name "GPO-Finanzas" -ReportType Html -Path $reportPath
Invoke-Item $reportPath
```

---

## 8️⃣ Filtrado con WMI (opcional)

```powershell
# -------------------------------------------------
# 8) Crear filtro WMI para solo Windows10
# -------------------------------------------------
Write-Host "`n[8] Creando filtro WMI OnlyWin10..." -ForegroundColor Cyan
New-GPWmiFilter -Name "OnlyWin10" `
    -Namespace "root\CIMv2" `
    -Query "SELECT * FROM Win32_OperatingSystem WHERE Version LIKE '10.%'"
# Aplicar filtro al GPO-Global
Set-GPLink -Name "GPO-Global" -Target "OU=Finanzas,$rootDN" -WmiFilter "OnlyWin10"
```

---

## 9️⃣ Limpieza final (opcional)

```powershell
# -------------------------------------------------
# 9) ELIMINAR GPOs de prueba
# -------------------------------------------------
Write-Host "`n[9] Eliminando GPOs demo..." -ForegroundColor Cyan
@("GPO-Sucursales","GPO-Finanzas","GPO-Global",
  "GPO-Sucursales-Remota","GPO-Sucursales-Restaurado") | 
  ForEach-Object { Remove-GPO -Name $_ -Confirm:$false }
```

---

🎉 **¡Listo!** Con estos 9 pasos cubres:

1. Creación de OUs
2. Creación y copia de GPOs
3. Edición de settings (USB)
4. Linkado a OUs
5. Backup e importación (.cab)
6. Reportes HTML
7. Filtros WMI
8. Limpieza

Cada bloque está diseñado para durar **3–5 min**, totalizando una demo de **\~30 min**. ¡A dar la sesión!
