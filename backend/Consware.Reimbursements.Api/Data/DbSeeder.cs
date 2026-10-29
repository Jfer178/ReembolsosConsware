using Consware.Reimbursements.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Consware.Reimbursements.Api.Data;

/// <summary>
/// Usuarios de demostración. Solo se ejecuta en Development (ver Program.cs);
/// los nombres coinciden con las solicitudes de prueba ya existentes.
/// </summary>
public static class DbSeeder
{
    private static readonly (string Username, string FullName, string Department, UserRole Role, string Password)[] DemoUsers =
    [
        ("empleado.demo", "Empleado Demo", "Comercial", UserRole.Employee, "Empleado2026!"),
        ("otra.persona", "Otra Persona", "Operaciones", UserRole.Employee, "Empleado2026!"),
        ("andres.ramirez", "Andrés Ramírez", "Equipo de Finanzas", UserRole.Approver, "Finanzas2026!"),
    ];

    public static async Task SeedDemoUsersAsync(AppDbContext db)
    {
        var existing = await db.Users.Select(u => u.Username).ToListAsync();

        foreach (var demo in DemoUsers.Where(d => !existing.Contains(d.Username)))
        {
            db.Users.Add(new User
            {
                Username = demo.Username,
                FullName = demo.FullName,
                Department = demo.Department,
                Role = demo.Role,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(demo.Password, workFactor: 11)
            });
        }

        await db.SaveChangesAsync();
    }
}
