using Consware.Reimbursements.Api.Data;
using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;

namespace Consware.Reimbursements.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AuthService auth, AppDbContext db) : ControllerBase
{
    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting("login")]
    public async Task<ActionResult<LoginResponseDto>> Login(LoginDto dto)
    {
        var result = await auth.LoginAsync(dto.Username, dto.Password);

        // Mensaje genérico: no revela si el usuario existe o si falló la contraseña.
        return result is null
            ? Unauthorized(new ErrorResponseDto("Usuario o contraseña incorrectos."))
            : Ok(result);
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<UserDto>> Me()
    {
        var username = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == username);
        return user is null
            ? Unauthorized(new ErrorResponseDto("La sesión ya no es válida. Inicia sesión de nuevo."))
            : Ok(AuthService.ToDto(user));
    }
}
