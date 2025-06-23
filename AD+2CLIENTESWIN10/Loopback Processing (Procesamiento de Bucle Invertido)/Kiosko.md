# Demo: Simulación de Laptop Kiosko con GPO

## Objetivo
Configurar una laptop (por ejemplo `WIN10-KIOSK01`) para funcionar como kiosko:
- Solo una aplicación disponible.
- Escritorio bloqueado.
- Sin acceso a configuraciones del sistema.
- Sesiones controladas.

---

## Escenario
- Dominio: `corp.contoso.com`
- Máquina: `WIN10-KIOSK01`
- Usuario: `usuario-kiosko`

---

## Paso a paso

### 1. Crear el usuario de kiosko
- En **Active Directory Users and Computers (ADUC)**:
  - Crear usuario `usuario-kiosko`.
  - Asignar contraseña fija (puede marcarse "password never expires").

### 2. Crear la OU "Kioskos"
- Crear OU llamada `Kioskos`.
- Mover `WIN10-KIOSK01` dentro de esta OU.

### 3. Crear la GPO
- En **Group Policy Management**, crear nueva GPO:
  - Nombre: `GPO - Kiosko WIN10`
  - Vincularla a la OU `Kioskos`.

### 4. Editar la GPO

#### A. Habilitar Loopback Processing (modo Replace)
- Navegar a:
  - `Computer Configuration -> Policies -> Administrative Templates -> System -> Group Policy`
- Configurar:
  - **User Group Policy loopback processing mode**: Enabled -> Replace

#### B. Limpiar el escritorio
- Navegar a:
  - `User Configuration -> Policies -> Administrative Templates -> Desktop -> Desktop`
- Configurar:
  - **Hide and disable all items on the desktop**: Enabled

#### C. Bloquear el acceso al panel de control
- Navegar a:
  - `User Configuration -> Policies -> Administrative Templates -> Control Panel`
- Configurar:
  - **Prohibit access to Control Panel and PC settings**: Enabled

#### D. Bloquear barra de tareas y comandos
- Navegar a:
  - `User Configuration -> Policies -> Administrative Templates -> Start Menu and Taskbar`
- Configurar:
  - **Prevent access to the command prompt**: Enabled
  - **Prevent changes to Taskbar and Start Menu Settings**: Enabled
  - **Remove Run menu from Start Menu**: Enabled
  - **Do not use the search-based method when resolving shell shortcuts**: Enabled

#### E. Definir aplicación de kiosko
- Navegar a:
  - `User Configuration -> Policies -> Administrative Templates -> System -> Custom User Interface`
- Configurar:
  - **Custom User Interface**: Enabled
  - Ruta de la aplicación, por ejemplo:
    - `C:\Windows\System32\mspaint.exe`

### 5. (Opcional) Deshabilitar acceso remoto
- Navegar a:
  - `Computer Configuration -> Policies -> Administrative Templates -> System -> Remote Desktop Services`
- Configurar:
  - Deshabilitar Remote Desktop

### 6. Pruebas
- Reiniciar `WIN10-KIOSK01`.
- Iniciar sesión como `usuario-kiosko`.
- Verificar:
  - Solo se lanza la aplicación especificada.
  - Escritorio bloqueado.
  - Sin acceso al sistema.

---

## Explicación pedagógica
- **Loopback Replace**: fuerza que las políticas de usuario dependan de la máquina.
- **GPO centralizada**: permite configurar múltiples kioskos desde el dominio.
- **Ideal para escenarios de seguridad, control de acceso y dispositivos públicos.**
