namespace Consware.Reimbursements.Api.Services;

// Excepciones de negocio; el controller las traduce a 400, 404 y 409.

public class ReimbursementValidationException(string message) : Exception(message);

public class ReimbursementNotFoundException(int id)
    : Exception($"No existe una solicitud con id {id}.");

public class InvalidStatusTransitionException(string message) : Exception(message);
