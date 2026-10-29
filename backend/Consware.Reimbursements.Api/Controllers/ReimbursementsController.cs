using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Models;
using Consware.Reimbursements.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Consware.Reimbursements.Api.Controllers;

// Todas las rutas exigen sesión. El empleado solo crea y consulta lo suyo; solo el aprobador decide.
[ApiController]
[Authorize]
[Route("api/reimbursements")]
public class ReimbursementsController(IReimbursementService service) : ControllerBase
{
    private const string Employee = nameof(UserRole.Employee);
    private const string Approver = nameof(UserRole.Approver);

    // El nombre sale del token firmado, nunca del cuerpo de la petición.
    private string CurrentName => User.FindFirst(AppClaims.Name)?.Value ?? string.Empty;
    private bool IsApprover => User.IsInRole(Approver);

    [HttpPost]
    [Authorize(Roles = Employee)]
    public async Task<ActionResult<ReimbursementResponseDto>> Create(CreateReimbursementDto dto)
    {
        try
        {
            var created = await service.CreateAsync(dto, CurrentName);
            return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
        }
        catch (ReimbursementValidationException ex)
        {
            return BadRequest(new ErrorResponseDto(ex.Message));
        }
    }

    [HttpGet]
    public async Task<ActionResult<List<ReimbursementResponseDto>>> GetAll(
        [FromQuery] string? status,
        [FromQuery] string? employeeName)
    {
        try
        {
            // Un empleado siempre ve solo sus solicitudes, aunque pida las de otro.
            var name = IsApprover ? employeeName : CurrentName;
            return Ok(await service.GetAllAsync(status, name));
        }
        catch (ReimbursementValidationException ex)
        {
            return BadRequest(new ErrorResponseDto(ex.Message));
        }
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ReimbursementResponseDto>> GetById(int id)
    {
        var item = await service.GetByIdAsync(id);

        // A un empleado, la solicitud ajena se le responde como inexistente para no revelar datos.
        return item is null || (!IsApprover && item.EmployeeName != CurrentName)
            ? NotFound(new ErrorResponseDto($"No existe una solicitud con id {id}."))
            : Ok(item);
    }

    [HttpPatch("{id:int}/approve")]
    [Authorize(Roles = Approver)]
    public Task<ActionResult<ReimbursementResponseDto>> Approve(int id) =>
        Decide(() => service.ApproveAsync(id, CurrentName));

    [HttpPatch("{id:int}/reject")]
    [Authorize(Roles = Approver)]
    public Task<ActionResult<ReimbursementResponseDto>> Reject(int id, RejectReimbursementDto dto) =>
        Decide(() => service.RejectAsync(id, dto.Reason, CurrentName));

    private async Task<ActionResult<ReimbursementResponseDto>> Decide(
        Func<Task<ReimbursementResponseDto>> action)
    {
        try
        {
            return Ok(await action());
        }
        catch (ReimbursementValidationException ex)
        {
            return BadRequest(new ErrorResponseDto(ex.Message));
        }
        catch (ReimbursementNotFoundException ex)
        {
            return NotFound(new ErrorResponseDto(ex.Message));
        }
        catch (InvalidStatusTransitionException ex)
        {
            return Conflict(new ErrorResponseDto(ex.Message));
        }
    }
}
