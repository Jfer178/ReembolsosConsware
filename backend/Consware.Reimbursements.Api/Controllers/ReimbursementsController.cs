using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Consware.Reimbursements.Api.Controllers;

[ApiController]
[Route("api/reimbursements")]
public class ReimbursementsController(IReimbursementService service) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<ReimbursementResponseDto>> Create(CreateReimbursementDto dto)
    {
        try
        {
            var created = await service.CreateAsync(dto);
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
            return Ok(await service.GetAllAsync(status, employeeName));
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
        return item is null
            ? NotFound(new ErrorResponseDto($"No existe una solicitud con id {id}."))
            : Ok(item);
    }

    [HttpPatch("{id:int}/approve")]
    public Task<ActionResult<ReimbursementResponseDto>> Approve(int id) =>
        Decide(() => service.ApproveAsync(id));

    [HttpPatch("{id:int}/reject")]
    public Task<ActionResult<ReimbursementResponseDto>> Reject(int id, RejectReimbursementDto dto) =>
        Decide(() => service.RejectAsync(id, dto.Reason));

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
