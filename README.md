# Control de finanzas personales

App web de una sola página para llevar ingresos, gastos, ahorro, deudas e inversiones.
No necesita servidor propio: es un archivo HTML que se publica gratis en GitHub Pages
y guarda los datos en Supabase para que se sincronicen entre el celular y el computador.

## Archivos

| Archivo | Para qué sirve | ¿Va al repositorio? |
|---|---|---|
| `index.html` | La aplicación completa. Es lo único que se necesita para que el sitio funcione. | Sí, obligatorio |
| `supabase.sql` | El script que crea la tabla y los permisos en la base de datos. | Sí, para no perderlo |
| `README.md` | Este instructivo. | Sí, para no perderlo |

---

## Parte 1 · Publicar la app en GitHub Pages

1. Crea una cuenta gratuita en <https://github.com/signup>. Confirma el correo.
2. Arriba a la derecha, haz clic en **+** → **New repository**.
3. Llena así:
   - **Repository name**: `finanzas`
   - Marca **Public** (Pages gratis solo funciona con repositorios públicos).
   - No marques nada más.
   - Botón verde **Create repository**.
4. En la página que aparece, haz clic en el enlace **uploading an existing file**.
5. Arrastra los tres archivos (`index.html`, `supabase.sql`, `README.md`).
6. Abajo, botón verde **Commit changes**.
7. Pestaña **Settings** (arriba) → en el menú izquierdo, **Pages**.
8. En **Build and deployment → Source**, elige **Deploy from a branch**.
   En **Branch** selecciona `main` y la carpeta `/ (root)`. **Save**.
9. Espera uno o dos minutos y recarga. Aparecerá la dirección del sitio:

   ```
   https://TU-USUARIO.github.io/finanzas/
   ```

Ya funciona. Sin la Parte 2, los datos quedan guardados solo en el navegador
de cada dispositivo.

---

## Parte 2 · Base de datos para sincronizar

### 2.1 Crear el proyecto

1. Entra a <https://supabase.com> → **Start your project** y regístrate (puedes usar la cuenta de GitHub).
2. **New project**:
   - **Name**: `finanzas`
   - **Database Password**: genera una y guárdala. No es la que usarás para entrar a la app,
     pero la puedes necesitar después.
   - **Region**: la más cercana (por ejemplo `South America (São Paulo)`).
3. Espera a que el proyecto quede en estado **Active** (uno o dos minutos).

### 2.2 Crear la tabla

1. Menú izquierdo → **SQL Editor** → **New query**.
2. Pega todo el contenido de `supabase.sql` y presiona **Run**.
3. Debe responder `Success`. La última consulta muestra `rowsecurity = true`: eso confirma
   que la tabla quedó protegida.

### 2.3 Crear tu usuario

1. Menú izquierdo → **Authentication** → pestaña **Users** → **Add user** → **Create new user**.
2. Escribe tu correo y una contraseña (esta sí es la que usarás para entrar a la app).
3. Activa **Auto Confirm User** para no tener que confirmar por correo.
4. **Create user**.

### 2.4 Copiar las dos claves

1. Arriba a la derecha del panel, botón **Connect**.
2. Copia:
   - **Project URL** → algo como `https://abcdefghijklmn.supabase.co`
   - **Publishable key** → empieza por `sb_publishable_...`

> Si el proyecto es antiguo verás `anon public` en vez de `publishable key`. Sirve igual.

### 2.5 Pegar las claves en la app

1. En tu repositorio de GitHub, abre `index.html` → ícono del lápiz (**Edit this file**).
2. Presiona `Ctrl+F` (o `Cmd+F`) y busca `SUPABASE_URL`. Está cerca de la línea 700.
3. Deja el bloque así, con tus datos entre comillas:

   ```js
   const CONFIG = {
     SUPABASE_URL: "https://abcdefghijklmn.supabase.co",
     SUPABASE_KEY: "sb_publishable_xxxxxxxxxxxxxxxxx"
   };
   ```

4. **Commit changes**. Espera un minuto y recarga tu sitio.
5. Aparecerá la pantalla de acceso. Entra con el correo y la contraseña del paso 2.3.

Listo: registra un gasto en el celular y aparece en el computador al recargar.

> Si prefieres no escribir las claves dentro del archivo, deja `CONFIG` vacío.
> La app las pedirá en la pantalla de acceso, dentro de *Datos de mi proyecto de Supabase*,
> y las guardará en ese navegador. Tendrás que escribirlas una vez por dispositivo.

---

## Instalar en el celular

Abre tu sitio en el navegador del teléfono:

- **iPhone**: botón Compartir → *Añadir a pantalla de inicio*.
- **Android**: menú ⋮ → *Añadir a pantalla principal*.

Queda con ícono propio y se abre a pantalla completa, como una aplicación.

---

## Parte 3 · Aprobar quién puede crear una cuenta (opcional)

Por defecto, cualquiera con el enlace de tu sitio puede darle a "crear mi cuenta". Esto agrega
un candado real: solo se crea la cuenta si el correo está en una lista que tú controlas. No es
un filtro que viva en la página (eso se podría saltar); Supabase lo revisa en su propio servidor
antes de que la cuenta llegue a existir.

### 3.1 Correr el script

1. Abre de nuevo el **SQL Editor** de tu proyecto → **New query**.
2. Pega la sección **"PARTE 2"** del `supabase.sql` actualizado (o el archivo completo, es seguro
   volver a correrlo) y presiona **Run**.
3. Edita la lista de correos autorizados directamente en ese mismo script antes de correrlo,
   o dile a Claude que lo haga por ti.

### 3.2 Activar el candado

Esto sí es un paso aparte, que no se hace por SQL:

1. Menú izquierdo → **Authentication** → pestaña **Hooks**.
2. Busca **Before User Created** → actívalo.
3. Elige **Postgres Function** como tipo, y selecciona `hook_aprobar_registro`.
4. **Save**.

Desde ese momento, cualquiera que intente crear una cuenta con un correo que no esté en la lista
verá el mensaje "Este correo todavía no está autorizado...". Los correos que sí agregaste pueden
registrarse con total normalidad.

### 3.3 Aprobar a alguien más adelante

No hace falta repetir el script completo. Dos formas, la que te resulte más cómoda:

- **Table Editor** (sin escribir SQL): menú izquierdo → **Table Editor** → tabla `invitados` →
  botón **Insert** → **Insert row** → pega el correo → **Save**.
- **SQL Editor**: `insert into public.invitados (email) values ('nuevo-correo@ejemplo.com');`

### Qué sí y qué no cubre esto

- Solo afecta a cuentas **nuevas**. Las que ya se crearon antes de activar el candado siguen
  existiendo tal cual.
- Es un filtro de invitación: tú decides quién puede entrar *antes* de que lo intente, escribiendo
  su correo en la lista. Si prefieres que cualquiera pueda pedir acceso y tú lo apruebes
  *después* de ver la solicitud, es una variante distinta y bastante más elaborada de construir;
  para dos o tres personas de confianza, la lista de invitados cumple exactamente lo mismo con
  mucho menos esfuerzo.
- Si nunca activas el paso 3.2, el script de la Parte 2 no hace nada por sí solo: la tabla y la
  función quedan creadas pero sin usarse, y el registro sigue abierto como antes.

---

## Parte 4 · Copias de seguridad automáticas

Además de todo lo anterior, la app guarda sola una versión de tus datos, como mucho una vez
al día, justo antes de reemplazar lo que ya tenías guardado. Así, si algún día algo saliera
mal — un error de la app, un "empezar de cero" sin querer, un dispositivo nuevo comportándose
raro — siempre queda un punto reciente al que volver.

No pide contraseña ni clave aparte: queda protegido exactamente igual que el resto de tus
datos (solo tu usuario y contraseña pueden leerlo). No hace falta configurar nada más: si ya
corriste el `supabase.sql` actualizado, esto ya está funcionando.

**Para ver o restaurar una copia:** dentro de la app, menú "Datos" → "Ver copias automáticas".
Vas a ver una lista con la fecha de cada una y cuántos movimientos tenía guardados en ese
momento. El botón "Restaurar" reemplaza lo que tienes ahora por esa copia — pide confirmación
antes, porque no se puede deshacer.

Se conservan las 20 copias más recientes por persona; las más viejas se van borrando solas.

---

## Cosas que conviene saber

- **La clave publishable es pública a propósito.** Cualquiera puede verla en el código
  del sitio. Lo que protege tus datos es tu contraseña más las reglas de seguridad
  del paso 2.2. Por eso ese script no es opcional.
- **Supabase pausa los proyectos gratuitos tras una semana sin actividad.** Si usas la
  app cada pocos días no pasa nada. Si se pausa, se reactiva desde el panel de Supabase
  sin perder información.
- **El plan gratuito no guarda copias de seguridad.** Usa de vez en cuando
  *Datos → Exportar copia de seguridad (JSON)* y guarda el archivo.
- **Si editas en dos dispositivos a la vez**, gana el último que guarde. Para uso
  personal no suele ser un problema.
- **Para actualizar la app**, sube de nuevo `index.html` al repositorio: GitHub Pages
  publica los cambios en menos de un minuto.
- **Seguridad**: la app escapa todo el texto que tú mismo escribes antes de mostrarlo (para
  que no pueda interpretarse como código), neutraliza fórmulas al exportar a CSV, cierra la
  sesión también del lado del servidor (no solo en el navegador) y declara una política de
  seguridad de contenido (CSP) que bloquea scripts y conexiones a cualquier sitio que no sea
  el tuyo. La base de datos también limita el tamaño máximo de cada fila como red de seguridad.
