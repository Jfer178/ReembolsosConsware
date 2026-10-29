namespace Consware.Reimbursements.Api.DTOs;

public record LoginDto(string? Username, string? Password);

public record UserDto(string Username, string FullName, string Department, string Role);

public record LoginResponseDto(string Token, DateTime ExpiresAtUtc, UserDto User);
