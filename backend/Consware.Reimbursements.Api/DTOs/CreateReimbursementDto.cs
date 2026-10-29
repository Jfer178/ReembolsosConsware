namespace Consware.Reimbursements.Api.DTOs;

// El empleado no viaja en el cuerpo: se toma del token, para que nadie cree solicitudes a nombre de otro.
// Los textos son anulables a propósito: la validación (con mensajes en español)
// vive en ReimbursementService y no en la validación automática de ASP.NET.
public record CreateReimbursementDto(
    decimal Amount,
    string? Category,
    string? Description);
