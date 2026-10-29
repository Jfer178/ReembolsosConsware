using Consware.Reimbursements.Api.DTOs;

namespace Consware.Reimbursements.Api.Services;

public interface IReimbursementService
{
    Task<ReimbursementResponseDto> CreateAsync(CreateReimbursementDto dto, string employeeName);
    Task<List<ReimbursementResponseDto>> GetAllAsync(string? status, string? employeeName);
    Task<ReimbursementResponseDto?> GetByIdAsync(int id);
    Task<ReimbursementResponseDto> ApproveAsync(int id, string decidedBy);
    Task<ReimbursementResponseDto> RejectAsync(int id, string? reason, string decidedBy);
}
