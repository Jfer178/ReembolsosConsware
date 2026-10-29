namespace Consware.Reimbursements.Api.DTOs;

// Los textos son anulables a propósito: la validación (con mensajes en español)
// vive en ReimbursementService y no en la validación automática de ASP.NET.
public record CreateReimbursementDto(
    string? EmployeeName,
    decimal Amount,
    string? Category,
    string? Description);
