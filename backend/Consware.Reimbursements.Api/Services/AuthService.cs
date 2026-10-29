using System.Security.Claims;
using System.Text;
using Consware.Reimbursements.Api.Data;
using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace Consware.Reimbursements.Api.Services;

public class JwtOptions
{
    public string Issuer { get; set; } = "Consware.Reimbursements";
    public string Audience { get; set; } = "Consware.Reimbursements.Clients";
    public int ExpiresMinutes { get; set; } = 480;
    public string Key { get; set; } = string.Empty;

    public SymmetricSecurityKey SigningKey => new(Encoding.UTF8.GetBytes(Key));
}

public static class AppClaims
{
    public const string Name = "name";
    public const string Role = "role";
    public const string Department = "department";
}

public class AuthService(AppDbContext db, JwtOptions jwt)
{
    // Hash válido de una contraseña al azar: se verifica también cuando el usuario no existe,
    // para que el tiempo de respuesta no revele qué usuarios están registrados.
    private static readonly string DummyHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString(), workFactor: 11);

    public async Task<LoginResponseDto?> LoginAsync(string? username, string? password)
    {
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrEmpty(password))
            return null;

        var normalized = username.Trim().ToLowerInvariant();
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == normalized);

        var valid = BCrypt.Net.BCrypt.Verify(password, user?.PasswordHash ?? DummyHash);
        if (user is null || !valid)
            return null;

        var expires = DateTime.UtcNow.AddMinutes(jwt.ExpiresMinutes);
        var token = new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = jwt.Issuer,
            Audience = jwt.Audience,
            Expires = expires,
            SigningCredentials = new SigningCredentials(jwt.SigningKey, SecurityAlgorithms.HmacSha256),
            Subject = new ClaimsIdentity(
            [
                new Claim(JwtRegisteredClaimNames.Sub, user.Username),
                new Claim(AppClaims.Name, user.FullName),
                new Claim(AppClaims.Role, user.Role.ToString()),
                new Claim(AppClaims.Department, user.Department),
            ])
        });

        return new LoginResponseDto(token, expires, ToDto(user));
    }

    public static UserDto ToDto(User user) =>
        new(user.Username, user.FullName, user.Department, user.Role.ToString());
}
