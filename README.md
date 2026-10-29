# Consware — Sistema de Reembolso de Gastos

MVP de la prueba técnica Fullstack: API ASP.NET Core + SQL Server, app Flutter para empleados y panel Angular para el aprobador.

> README en construcción: se completará con comandos verificados al terminar cada parte.

## Estructura

```text
backend/Consware.Reimbursements.Api/   API REST (ASP.NET Core 10, EF Core 10, SQL Server)
mobile/                                App Flutter del empleado (pendiente)
web/                                   Panel Angular del aprobador (pendiente)
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

## Regla de negocio

- Monto ≤ $500.000 COP → `Approved` automáticamente.
- Monto > $500.000 COP → `Pending`.
- Rechazar exige motivo no vacío. `Approved` y `Rejected` son estados finales (409 si se intenta decidir otra vez).

## Pruebas realizadas

Backend, ejecutadas con `curl` contra la API real y SQL Server (29/10/2026):

- T01–T16 de la matriz de la guía: todas correctas, incluidos el límite exacto (500000 → Approved; 500000,01 y 500001 → Pending), las validaciones 400, los 404 y los 409 por estado final.
- Extras: monto no numérico → 400; `?status=Foo` y `?status=1` → 400; fechas devueltas en UTC con `Z`.
- CORS: el preflight desde `http://localhost:4200` es aceptado y otros orígenes no reciben cabeceras CORS.
- T20: los datos siguen disponibles tras reiniciar la API.
