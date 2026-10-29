namespace Consware.Reimbursements.Api.DTOs;

// Formato único de error de la API: {"message": "..."}
public record ErrorResponseDto(string Message);
