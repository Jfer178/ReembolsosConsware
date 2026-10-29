using Consware.Reimbursements.Api.Data;
using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Consware.Reimbursements.Api.Services;

public class ReimbursementService(AppDbContext db) : IReimbursementService
{
    // Montos menores o iguales a este valor (COP) se aprueban automáticamente.
    public const decimal AutoApprovalLimit = 500_000m;

    private const int EmployeeNameMaxLength = 100;
    private const int CategoryMaxLength = 60;
    private const int TextMaxLength = 500;

    public async Task<ReimbursementResponseDto> CreateAsync(CreateReimbursementDto dto)
    {
        var employeeName = RequireText(dto.EmployeeName, "nombre del empleado", EmployeeNameMaxLength);
        var category = RequireText(dto.Category, "categoría", CategoryMaxLength);
        var description = RequireText(dto.Description, "descripción", TextMaxLength);

        if (dto.Amount <= 0)
            throw new ReimbursementValidationException("El monto debe ser mayor a cero.");

        var now = DateTime.UtcNow;
        var status = dto.Amount <= AutoApprovalLimit
            ? ReimbursementStatus.Approved
            : ReimbursementStatus.Pending;

        var entity = new ReimbursementRequest
        {
            EmployeeName = employeeName,
            Amount = dto.Amount,
            Category = category,
            Description = description,
            Status = status,
            CreatedAtUtc = now,
            DecidedAtUtc = status == ReimbursementStatus.Approved ? now : null
        };

        db.ReimbursementRequests.Add(entity);
        await db.SaveChangesAsync();
        return ToDto(entity);
    }

    public async Task<List<ReimbursementResponseDto>> GetAllAsync(string? status, string? employeeName)
    {
        var query = db.ReimbursementRequests.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
        {
            var parsed = ParseStatus(status);
            query = query.Where(x => x.Status == parsed);
        }

        if (!string.IsNullOrWhiteSpace(employeeName))
        {
            var name = employeeName.Trim();
            query = query.Where(x => x.EmployeeName == name);
        }

        var items = await query
            .OrderByDescending(x => x.CreatedAtUtc)
            .ThenByDescending(x => x.Id)
            .ToListAsync();

        return items.Select(ToDto).ToList();
    }

    public async Task<ReimbursementResponseDto?> GetByIdAsync(int id)
    {
        var entity = await db.ReimbursementRequests.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
        return entity is null ? null : ToDto(entity);
    }

    public async Task<ReimbursementResponseDto> ApproveAsync(int id)
    {
        var entity = await FindPendingAsync(id);

        entity.Status = ReimbursementStatus.Approved;
        entity.DecidedAtUtc = DateTime.UtcNow;

        await db.SaveChangesAsync();
        return ToDto(entity);
    }

    public async Task<ReimbursementResponseDto> RejectAsync(int id, string? reason)
    {
        var cleanReason = RequireText(reason, "motivo de rechazo", TextMaxLength);
        var entity = await FindPendingAsync(id);

        entity.Status = ReimbursementStatus.Rejected;
        entity.RejectionReason = cleanReason;
        entity.DecidedAtUtc = DateTime.UtcNow;

        await db.SaveChangesAsync();
        return ToDto(entity);
    }

    // Solo una solicitud Pending puede decidirse; Approved y Rejected son estados finales.
    private async Task<ReimbursementRequest> FindPendingAsync(int id)
    {
        var entity = await db.ReimbursementRequests.FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new ReimbursementNotFoundException(id);

        if (entity.Status != ReimbursementStatus.Pending)
            throw new InvalidStatusTransitionException(
                $"La solicitud {id} ya fue decidida (estado actual: {entity.Status}) y no puede cambiar.");

        return entity;
    }

    private static string RequireText(string? value, string fieldName, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ReimbursementValidationException($"El campo {fieldName} es obligatorio.");

        var trimmed = value.Trim();
        if (trimmed.Length > maxLength)
            throw new ReimbursementValidationException(
                $"El campo {fieldName} no puede superar {maxLength} caracteres.");

        return trimmed;
    }

    private static ReimbursementStatus ParseStatus(string status)
    {
        // Enum.TryParse acepta números ("1"); por eso se compara contra los nombres válidos.
        var match = Enum.GetNames<ReimbursementStatus>()
            .FirstOrDefault(name => name.Equals(status.Trim(), StringComparison.OrdinalIgnoreCase));

        if (match is null)
            throw new ReimbursementValidationException(
                $"Estado '{status}' no válido. Use Pending, Approved o Rejected.");

        return Enum.Parse<ReimbursementStatus>(match);
    }

    // SQL Server no guarda el "Kind" del DateTime; se marca como UTC para serializar con "Z".
    private static ReimbursementResponseDto ToDto(ReimbursementRequest x) => new(
        x.Id,
        x.EmployeeName,
        x.Amount,
        x.Category,
        x.Description,
        x.Status.ToString(),
        x.RejectionReason,
        DateTime.SpecifyKind(x.CreatedAtUtc, DateTimeKind.Utc),
        x.DecidedAtUtc is null ? null : DateTime.SpecifyKind(x.DecidedAtUtc.Value, DateTimeKind.Utc));
}
