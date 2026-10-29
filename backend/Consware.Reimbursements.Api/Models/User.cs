namespace Consware.Reimbursements.Api.Models;

public enum UserRole
{
    Employee,
    Approver
}

public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;
    public UserRole Role { get; set; }

    // Nunca se guarda la contraseña: solo su hash BCrypt (incluye sal y factor de costo).
    public string PasswordHash { get; set; } = string.Empty;
}
