
# Demo: Loopback Processing (Procesamiento de Bucle Invertido)

## Objetivo
Demostrar cómo aplicar políticas de usuario basadas en la ubicación (máquina) y no en el usuario que inicia sesión.

---

## Escenario

- Dominio: `local.curso.com`
- Sala de juntas: OU llamada `SalasJuntas`
- Usuarios de prueba: `usuario1`, `usuario2`, `usuario3`
- Computadora de prueba: `WIN10-SALA01`

Queremos que cualquier usuario que inicie sesión en las máquinas de `SalasJuntas` reciba un escritorio totalmente limpio, sin importar su perfil normal.

---

## Preparación previa

### 1. Crear la OU de prueba
- Abre **Active Directory Users and Computers (ADUC)**.
- Crea la OU `SalasJuntas`.
- Mueve dentro de esta OU una computadora de prueba: `WIN10-SALA01`.

### 2. Crear usuarios de prueba
- Crear `usuario1`, `usuario2` y `usuario3`.

---

## Configuración de la GPO con Loopback Processing

### 3. Crear la GPO
- Abre **Group Policy Management**.
- Botón derecho sobre `SalasJuntas` → **Create a GPO in this domain, and Link it here…**
- Nombre de la GPO: `GPO - SalaJuntas - Escritorio Restringido`.

### 4. Editar la GPO
- Navegar a:
  - `Computer Configuration > Policies > Administrative Templates > System > Group Policy`
- Habilitar: **User Group Policy loopback processing mode**
  - Seleccionar modo: **Replace**

---

## Configuración de restricciones de usuario dentro de la misma GPO

### 5. Configurar el escritorio restringido

- Navegar a:
  - `User Configuration > Policies > Administrative Templates > Desktop > Desktop`
- Habilitar:
  - **Hide and disable all items on the desktop**

- Opcional: bloquear el Panel de Control
  - `User Configuration > Policies > Administrative Templates > Control Panel`
  - **Prohibit access to Control Panel and PC settings** → Habilitado

---

## Pruebas

### 6. Probar el efecto de Loopback

- Iniciar `WIN10-SALA01`.
- Iniciar sesión con `usuario1`, `usuario2` o cualquier otro.
- Verificar:
  - Escritorio limpio.
  - Panel de control deshabilitado.
  - Restricciones aplicadas.

### 7. Comparación

- Iniciar sesión con los mismos usuarios en cualquier otra máquina fuera de `SalasJuntas`.
- Verificar que las restricciones **no** se aplican, y tienen su perfil normal.

---

## Explicación pedagógica

- **Sin Loopback:** las políticas de usuario siguen al usuario.
- **Con Loopback Replace:** las políticas de usuario se reemplazan según la máquina.
- **Modo Merge:** (sólo para referencia) combina políticas de usuario y máquina.
