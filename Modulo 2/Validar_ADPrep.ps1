
# Script para validar si ADPrep ya fue ejecutado correctamente

# 1. Obtener el nivel de esquema del bosque
$schemaVersion = (Get-ADObject (Get-ADRootDSE).schemaNamingContext -Property objectVersion).objectVersion
Write-Output "Versión del esquema del bosque: $schemaVersion"

# 2. Revisar si hay logs de adprep
$logPath = "C:\Windows\debug\adprep\logs"
if (Test-Path $logPath) {
    Write-Output "Se encontró la carpeta de logs de ADPrep: $logPath"
    Get-ChildItem $logPath | Select-Object Name, LastWriteTime
} else {
    Write-Output "No se encontró la carpeta de logs de ADPrep en $logPath"
}

# 3. Mostrar mensaje según versión del esquema
switch ($schemaVersion) {
    88 { Write-Output "✔️ El esquema corresponde a Windows Server 2022 (v88). ADPrep fue ejecutado." }
    87 { Write-Output "⚠️ El esquema corresponde a Windows Server 2016 (v87). No se ha ejecutado ADPrep para WS2022." }
    default { Write-Output "❓ Nivel de esquema desconocido. Revisa manualmente el entorno." }
}
