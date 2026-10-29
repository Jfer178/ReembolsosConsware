# Consware — Sistema de Reembolso de Gastos

MVP de la prueba técnica Fullstack: API ASP.NET Core + SQL Server, app Flutter para empleados y panel Angular para el aprobador.

## Descripción y alcance

Un empleado registra un gasto y consulta su estado desde la app móvil. Los gastos de hasta $500.000 COP se aprueban automáticamente; los de mayor valor quedan pendientes y un aprobador los aprueba o rechaza (con motivo obligatorio) desde el panel web. Una única API centraliza las reglas y guarda todo en SQL Server.

Las tres partes del enunciado están completas y probadas contra la base de datos real:

| Parte | Estado |
|---|---|
| 1. API REST con ASP.NET Core y SQL Server | Completa |
| 2. App Flutter para empleados | Completa (probada en emulador Android y en navegador) |
| 3. Panel Angular para el aprobador | Completa |

## Tecnologías

- **Backend:** ASP.NET Core 10 (Web API con controllers), Entity Framework Core 10, SQL Server 2025.
- **Móvil:** Flutter 3.44 / Dart 3.12, paquete `http`, estado con `setState`.
- **Web:** Angular 22 (componentes standalone, signals, `HttpClient`), SCSS.
- **Pruebas:** `curl` contra la API, `flutter test`, Vitest (`ng test`).

## Requisitos previos

- .NET SDK 10 y la herramienta `dotnet-ef` 10.x.
- SQL Server accesible (local o remoto) con permiso para crear la base, o una base vacía creada previamente.
- Flutter 3.44+ y, para Android, el SDK con un emulador (probado con Pixel 7 / Android 15).
- Node.js 24+ y npm.

## Demostración rápida

1. Levantar la API (`dotnet run` en el backend) y dejarla encendida.
2. Desde la app Flutter, registrar un gasto de $650.000: queda **Pendiente**.
3. En el panel Angular (`http://localhost:4210`), rechazarlo escribiendo un motivo.
4. En la app, deslizar para actualizar: aparece **Rechazada** con el motivo.
5. Reiniciar la API y consultar de nuevo: los datos siguen en SQL Server.

## Estructura

```text
backend/Consware.Reimbursements.Api/   API REST (ASP.NET Core 10, EF Core 10, SQL Server)
mobile/                                App Flutter del empleado
web/                                   Panel Angular del aprobador
docs/                                  Guía técnica de diseño
```

## Backend (API)

Requisitos: .NET SDK 10, herramienta `dotnet-ef` 10.x y una instancia de SQL Server accesible.

1. Ajustar `Server=` en `backend/Consware.Reimbursements.Api/appsettings.json` al nombre de su instancia
   (en desarrollo: `JEREMY\MSSQLSERVER2026`, autenticación integrada de Windows).
2. Crear la base y la tabla, y levantar la API:

```powershell
cd backend/Consware.Reimbursements.Api
dotnet restore
dotnet ef database update
dotnet run
```

La API queda en `http://localhost:5080/api/reimbursements`. Se usa el puerto 5080 porque el 5000 estaba ocupado por Docker en el equipo de desarrollo.
El archivo `Consware.Reimbursements.Api.http` contiene peticiones de ejemplo.

| Método | Ruta | Éxito / errores |
|---|---|---|
| POST | `/api/reimbursements` | 201 · 400 |
| GET | `/api/reimbursements?status=&employeeName=` | 200 · 400 (estado inválido) |
| GET | `/api/reimbursements/{id}` | 200 · 404 |
| PATCH | `/api/reimbursements/{id}/approve` | 200 · 404 · 409 |
| PATCH | `/api/reimbursements/{id}/reject` (`{"reason": "..."}`) | 200 · 400 · 404 · 409 |

Errores con formato `{"message": "..."}`.

Los orígenes de navegador permitidos por CORS se configuran en `appsettings.json` (`Cors:AllowedOrigins`):
`http://localhost:4210` (Angular) y `http://localhost:4300` (Flutter web).
Se usa 4210 en lugar del 4200 por defecto porque ese puerto también lo ocupaba Docker en el equipo de desarrollo.

## App móvil (Flutter)

Requisitos: Flutter 3.44+ y la API encendida. El empleado se identifica con el nombre fijo `Empleado Demo` (sin login, como permite el enunciado).

Pantallas: inicio con resumen por estado, registrar gasto (monto, categoría, descripción) y mis solicitudes (búsqueda, filtros por estado, orden, motivo de rechazo y detalle).
Diseño con la identidad de Consware (logo vectorial, azul marino) y la tipografía Poppins incluida en `assets/fonts` (licencia OFL).

```powershell
cd mobile
flutter pub get
flutter run -d chrome --web-port 4300       # navegador (Flutter web)
flutter run -d emulator-5554                # emulador Android
```

La URL de la API se elige sola en `lib/config/api_config.dart`: `localhost:5080` en web y `10.0.2.2:5080` en el emulador Android.
Para un celular físico: `flutter run --dart-define=API_BASE_URL=http://<IP-del-PC>:5080/api/reimbursements`
(y levantar la API con `dotnet run --urls http://0.0.0.0:5080`).

Pruebas: `flutter analyze` y `flutter test` (formatos, mapeo JSON, errores de la API, API apagada y listado con motivo de rechazo).

## Panel del aprobador (Angular)

Requisitos: Node 24+ y la API encendida. Angular 22 con componentes standalone y signals; íconos (Material Symbols) y fuente (Poppins) instalados como paquetes, sin depender de internet.

```powershell
cd web
npm install
npm start        # http://localhost:4210
```

Funcionalidad:

- **Panel de aprobación:** resumen por estado y monto aprobado; pestañas por estado (Pendientes por defecto); búsqueda por empleado, categoría, descripción o código; filtros por categoría y rango de monto; orden por fecha o monto; paginación.
- **En vivo:** la lista se sincroniza sola con la API cada 10 segundos (solo con la pestaña visible). Las solicitudes nuevas se resaltan, llegan a la campana de notificaciones y muestran un aviso; no hace falta pulsar "Actualizar".
- **Detalle:** al hacer clic en una solicitud se abre un panel con su ficha completa y el historial (creada, enviada a revisión, decisión y tiempo de respuesta). La URL incluye `?solicitud=ID`, así que se puede enlazar.
- **Aprobar:** desde la tabla o el detalle, con confirmación (`PATCH /{id}/approve`). Selección múltiple para aprobar varias pendientes a la vez.
- **Rechazar:** desde el detalle, con motivo obligatorio (máx. 500 caracteres); la UI bloquea el motivo vacío y la API también lo valida.
- **Reportes:** solicitudes y montos totales, porcentaje de aprobación automática, tiempo promedio de revisión manual, distribución por estado, monto por categoría, resumen por empleado y últimas decisiones.
- **Errores:** si otra persona ya decidió la solicitud (409), se informa y la lista se sincroniza. Si la API se cae, se conservan los últimos datos con el indicador "Sin conexión · reintentando".

La URL de la API está en `src/app/api.config.ts`. Pruebas: `npx ng test --watch=false`.

## Regla de negocio

- Monto ≤ $500.000 COP → `Approved` automáticamente.
- Monto > $500.000 COP → `Pending`.
- Rechazar exige motivo no vacío. `Approved` y `Rejected` son estados finales (409 si se intenta decidir otra vez).

## Pruebas realizadas

Backend, ejecutadas con `curl` contra la API real y SQL Server (29/10/2026):

- T01–T16 de la matriz de la guía: todas correctas, incluidos el límite exacto (500000 → Approved; 500000,01 y 500001 → Pending), las validaciones 400, los 404 y los 409 por estado final.
- Extras: monto no numérico → 400; `?status=Foo` y `?status=1` → 400; fechas devueltas en UTC con `Z`.
- CORS: el preflight desde los orígenes configurados (`http://localhost:4210` y `http://localhost:4300`) es aceptado y otros orígenes no reciben cabeceras CORS.
- T20: los datos siguen disponibles tras reiniciar la API.

App Flutter:

- `flutter analyze` sin problemas y `flutter test` con 8 de 8 pruebas correctas.
- Flutter web (release, puerto 4300) cargando las solicitudes reales de la API; el preflight CORS para POST desde `localhost:4300` es aceptado.
- Emulador Android (Pixel 7, Android 15) contra la API en `10.0.2.2:5080`: se registró desde el formulario un gasto de $650.000 (Tiquetes), quedó `Pending` en SQL Server y la lista se actualizó con el aviso de aprobación manual.

Panel Angular (contra la API real y SQL Server):

- `ng build` sin advertencias y `ng test` con 7 de 7 pruebas correctas (servicio HTTP, formatos, tiempos relativos y mensajes de error).
- Actualización en vivo: con el panel abierto se crearon 4 solicitudes por la API y, sin interacción, aparecieron resaltadas como nuevas, con la campana y el contador lateral en 4 y el aviso de llegada.
- Detalle: clic en una fila abre la ficha con su historial y la marca como vista; desde ahí se rechazó con motivo.
- Aprobación múltiple de 2 solicitudes con confirmación; filtros (más de $500.000) y paginación verificados.
- Rechazo sin motivo bloqueado en la UI (T19); rechazo con motivo guardado en SQL Server con su fecha.
- Aprobación con confirmación guardada en SQL Server.
- Conflicto: una solicitud aprobada por fuera muestra el aviso de 409 y la tabla se recarga.
- Con la API apagada aparece el error con "Reintentar", que recupera los datos al volver la API.

## Decisiones técnicas

- **SQL Server:** cumple el requisito de base SQL real, estaba disponible en el equipo y permite usar `DECIMAL(18,2)` para montos y migraciones de EF Core. El esquema se crea solo con migraciones (no hay scripts manuales en paralelo).
- **Una sola API, dos clientes:** Flutter y Angular nunca acceden a la base; la API es la única fuente de verdad para crear y decidir solicitudes.
- **Reglas en el servicio, no en el controller ni en las interfaces:** `ReimbursementService` contiene el límite de $500.000, las validaciones y las transiciones de estado. Los clientes validan solo para dar una mejor experiencia; la API vuelve a validar todo.
- **Restricciones `CHECK` en la tabla:** monto positivo, estados válidos y motivo obligatorio al rechazar, como defensa adicional a las validaciones del servicio.
- **Una sola tabla:** el enunciado permite identificar al empleado con un nombre fijo, así que no hay tabla de usuarios ni login. Las categorías son una lista controlada por la interfaz.
- **Monolito pequeño:** un dominio y un flujo de decisión no justifican microservicios; la separación Controller / Service / DTOs / Data mantiene el código ordenado sin sobreingeniería.
- **Errores uniformes:** todas las respuestas de error son `{"message": "..."}` en español, y los 500 no exponen detalles de SQL Server.
- **Puertos 5080 y 4210:** los puertos por defecto (5000 y 4200) estaban ocupados por Docker en el equipo de desarrollo. Ambos son configurables (`launchSettings.json`, `angular.json`).

## Fuera de alcance

No se implementó porque el enunciado no lo pide y habría restado tiempo a lo obligatorio. Así se abordaría:

- **Autenticación y roles:** login con JWT o un proveedor de identidad; el aprobador y el empleado saldrían del token en lugar de un nombre fijo.
- **Comprobantes y fecha del gasto:** columnas nuevas y almacenamiento de archivos (por ejemplo, Blob Storage) con validación de tipo y tamaño.
- **Concurrencia entre aprobadores:** hoy se evita decidir dos veces validando el estado (409); en producción se añadiría `rowversion` para control optimista.
- **Tiempo real con push:** el panel consulta la API cada 10 s, suficiente para este volumen; con más aprobadores se usaría SignalR para enviar los cambios desde el servidor.
- **Notificaciones, auditoría y reportes:** registro de quién decidió cada solicitud y aviso al empleado.
- **Pruebas automatizadas del backend y CI:** pruebas de integración de la API y un pipeline que ejecute las pruebas de los tres proyectos.

## Uso de IA

Utilicé **Claude Code** (asistente de programación de Anthropic) para acelerar la escritura de código, la ejecución de pruebas y el diagnóstico de problemas del entorno. Las decisiones de producto, diseño y criterio técnico fueron mías: trabajé por partes, revisé cada resultado antes de avanzar y, cuando una propuesta no cumplía lo que buscaba, la rechacé y exploré otra alternativa.

### Qué hizo la IA

- Generar la primera versión del código de las tres partes a partir de la guía técnica del proyecto (`docs/`).
- Ejecutar la matriz de pruebas contra la API y probar la app en el emulador Android.
- Diagnosticar problemas del entorno: puertos ocupados por Docker, codificación de caracteres en PowerShell y CORS.

### Decisiones que tomé

**Visual**

- Rechacé el primer diseño de la app por ser genérico y pedí rehacerlo a partir de mockups propios de la app y del panel, con la identidad de Consware: logo, paleta azul marino, tipografía, tarjetas y estados.
- Revisé el resultado pantalla por pantalla y pedí corregir detalles: textos cortados en las tarjetas, la ilustración superpuesta al avatar y una columna de la tabla que no cabía.
- Comparé probar solo en el navegador con montar un emulador Android, y elegí el emulador para que la demostración reflejara una app móvil real, dejando Flutter web como respaldo.
- Dejé fuera de los mockups los elementos sin funcionalidad real (notificaciones, perfil, comprobantes, comparación con el mes anterior) para no mostrar controles vacíos.

**Lógica**

- Definí la regla en el límite: $500.000 exactos se aprueban y $500.000,01 queda pendiente, y lo verifiqué con casos de prueba en ambos lados del umbral.
- Mantuve las reglas en un servicio separado del controller, con validación doble: los clientes validan para dar una mejor experiencia y la API es la autoridad final.
- Establecí que una solicitud aprobada o rechazada no puede volver a decidirse (409) y que el panel se recargue si otra persona ya la decidió.
- Avancé por etapas (backend, Flutter, Angular) con commits que reflejan cada avance probado, como prioriza el enunciado.

**Seguridad**

- Sin credenciales en el repositorio: la conexión a SQL Server usa autenticación integrada de Windows.
- Actualicé dependencias con vulnerabilidades conocidas (`Microsoft.OpenApi`, `System.Security.Cryptography.Pkcs`) en lugar de ignorar las advertencias de NuGet.
- CORS restringido a orígenes explícitos y configurables, en lugar de permitir cualquier origen.
- Los errores 500 no exponen detalles de SQL Server, y la API valida longitudes y formatos antes de guardar.
- Restricciones `CHECK` en la base como defensa adicional a la validación del servicio.
- HTTP sin cifrar permitido solo en el build de depuración de Android, y `TrustServerCertificate` documentado como exclusivo de desarrollo.

### Verificación

- Probé los endpoints, la persistencia en SQL Server y la integración de ambos clientes, incluido el flujo completo: registrar un gasto en la app, decidirlo en el panel y ver el resultado de vuelta en la app.
- Puedo explicar y modificar el código y cada una de estas decisiones.
