using Consware.Reimbursements.Api.Data;
using Consware.Reimbursements.Api.DTOs;
using Consware.Reimbursements.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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

builder.Services.AddCors(options =>
    options.AddPolicy("AngularLocal", policy =>
        policy.WithOrigins("http://localhost:4200")
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
}

app.UseCors("AngularLocal");
app.MapControllers();

app.Run();
