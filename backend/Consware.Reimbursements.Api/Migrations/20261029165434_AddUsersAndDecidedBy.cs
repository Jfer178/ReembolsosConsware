using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Consware.Reimbursements.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddUsersAndDecidedBy : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DecidedBy",
                table: "ReimbursementRequests",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            // Las solicitudes previas aprobadas por la regla automática quedan atribuidas al sistema.
            migrationBuilder.Sql(
                "UPDATE dbo.ReimbursementRequests SET DecidedBy = N'Sistema' " +
                "WHERE Status = 'Approved' AND Amount <= 500000 AND DecidedBy IS NULL;");

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Username = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    FullName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Department = table.Column<string>(type: "nvarchar(60)", maxLength: 60, nullable: false),
                    Role = table.Column<string>(type: "varchar(16)", unicode: false, maxLength: 16, nullable: false),
                    PasswordHash = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username",
                table: "Users",
                column: "Username",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropColumn(
                name: "DecidedBy",
                table: "ReimbursementRequests");
        }
    }
}
