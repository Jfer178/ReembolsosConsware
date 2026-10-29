using Consware.Reimbursements.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Consware.Reimbursements.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options) { }

    public DbSet<ReimbursementRequest> ReimbursementRequests => Set<ReimbursementRequest>();
    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var user = modelBuilder.Entity<User>();
        user.ToTable("Users");
        user.HasKey(x => x.Id);
        user.Property(x => x.Username).IsRequired().HasMaxLength(50).IsUnicode(false);
        user.Property(x => x.FullName).IsRequired().HasMaxLength(100);
        user.Property(x => x.Department).IsRequired().HasMaxLength(60);
        user.Property(x => x.PasswordHash).IsRequired().HasMaxLength(100).IsUnicode(false);
        user.Property(x => x.Role).HasConversion<string>().HasMaxLength(16).IsUnicode(false);
        user.HasIndex(x => x.Username).IsUnique();

        var entity = modelBuilder.Entity<ReimbursementRequest>();

        // Las restricciones CHECK son una defensa adicional; las reglas se validan en el servicio.
        entity.ToTable("ReimbursementRequests", table =>
        {
            table.HasCheckConstraint("CK_Reimbursements_Amount", "[Amount] > 0");
            table.HasCheckConstraint("CK_Reimbursements_Status",
                "[Status] IN ('Pending','Approved','Rejected')");
            table.HasCheckConstraint("CK_Reimbursements_RejectionReason",
                "[Status] <> 'Rejected' OR ([RejectionReason] IS NOT NULL AND LEN(LTRIM(RTRIM([RejectionReason]))) > 0)");
        });

        entity.HasKey(x => x.Id);
        entity.Property(x => x.EmployeeName).IsRequired().HasMaxLength(100);
        entity.Property(x => x.Amount).HasPrecision(18, 2).IsRequired();
        entity.Property(x => x.Category).IsRequired().HasMaxLength(60);
        entity.Property(x => x.Description).IsRequired().HasMaxLength(500);
        entity.Property(x => x.RejectionReason).HasMaxLength(500);
        entity.Property(x => x.DecidedBy).HasMaxLength(100);
        entity.Property(x => x.Status)
              .HasConversion<string>()
              .HasMaxLength(16)
              .IsUnicode(false);
        entity.Property(x => x.CreatedAtUtc).HasColumnType("datetime2");
        entity.Property(x => x.DecidedAtUtc).HasColumnType("datetime2");

        entity.HasIndex(x => x.Status);
        entity.HasIndex(x => x.EmployeeName);
    }
}
