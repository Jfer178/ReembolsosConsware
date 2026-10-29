using System.Security.Cryptography;
using System.Threading.RateLimiting;
using Consware.Reimbursements.Api.Data;
using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .ConfigureApiBehaviorOptions(options =>
    {
        // JSON mal formado o tipos inválidos (p. ej. "amount": "abc") devuelven el mismo formato {"message"}.
        options.InvalidModelStateResponseFactory = _ =>
            new BadRequestObjectResult(new ErrorResponseDto(
                "La solicitud tiene un formato inválido. Revise los campos enviados."));
    });
builder.Services.AddOpenApi();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<IReimbursementService, ReimbursementService>();
builder.Services.AddScoped<AuthService>();

// ---------- Autenticación JWT ----------
// La clave de firma nunca va en el repositorio: se lee de user-secrets o de una variable de entorno (Jwt__Key).
var jwt = builder.Configuration.GetSection("Jwt").Get<JwtOptions>() ?? new JwtOptions();
if (string.IsNullOrWhiteSpace(jwt.Key))
{
    if (!builder.Environment.IsDevelopment())
        throw new InvalidOperationException("Falta configurar Jwt:Key (user-secrets o variable de entorno Jwt__Key).");

    // En desarrollo, sin clave configurada se genera una temporal: las sesiones se cierran al reiniciar la API.
    jwt.Key = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
    Console.WriteLine("Aviso: Jwt:Key no está configurada; se usa una clave temporal de desarrollo.");
}
builder.Services.AddSingleton(jwt);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = jwt.Issuer,
            ValidAudience = jwt.Audience,
            IssuerSigningKey = jwt.SigningKey,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
            NameClaimType = AppClaims.Name,
            RoleClaimType = AppClaims.Role
        };
        // 401 y 403 con el mismo formato {"message"} que el resto de la API.
        options.Events = new JwtBearerEvents
        {
            OnChallenge = async context =>
            {
                context.HandleResponse();
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await context.Response.WriteAsJsonAsync(
                    new ErrorResponseDto("Tu sesión no es válida o expiró. Inicia sesión de nuevo."));
            },
            OnForbidden = async context =>
            {
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                await context.Response.WriteAsJsonAsync(
                    new ErrorResponseDto("No tienes permiso para realizar esta acción."));
            }
        };
    });
builder.Services.AddAuthorization();

// Máximo 5 intentos de login por minuto por IP, para frenar ataques de fuerza bruta.
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("login", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "desconocida",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 5, Window = TimeSpan.FromMinutes(1) }));
    options.OnRejected = async (context, token) =>
        await context.HttpContext.Response.WriteAsJsonAsync(
            new ErrorResponseDto("Demasiados intentos de inicio de sesión. Espera un minuto e inténtalo de nuevo."),
            token);
});

// Orígenes de navegador permitidos (Angular y Flutter web). Flutter nativo no usa CORS.
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
builder.Services.AddCors(options =>
    options.AddPolicy("LocalFrontends", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()));

var app = builder.Build();

// Errores no previstos: 500 con mensaje genérico, sin exponer detalles de SQL Server.
app.UseExceptionHandler(errorApp => errorApp.Run(async context =>
{
    context.Response.StatusCode = StatusCodes.Status500InternalServerError;
    await context.Response.WriteAsJsonAsync(
        new ErrorResponseDto("Ocurrió un error inesperado en el servidor."));
}));

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    // Usuarios de demostración, solo en desarrollo.
    using var scope = app.Services.CreateScope();
    await DbSeeder.SeedDemoUsersAsync(scope.ServiceProvider.GetRequiredService<AppDbContext>());
}

app.UseCors("LocalFrontends");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.MapControllers();

app.Run();
