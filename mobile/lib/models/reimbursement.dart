enum ReimbursementStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const ReimbursementStatus(this.apiValue);

  final String apiValue;

  static ReimbursementStatus fromApi(String value) => values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => throw FormatException('Estado desconocido: $value'),
      );
}

class Reimbursement {
  // Misma política que el backend; solo se usa para mostrar avisos, la API decide el estado.
  static const autoApprovalLimit = 500000;

  const Reimbursement({
    required this.id,
    required this.employeeName,
    required this.amount,
    required this.category,
    required this.description,
    required this.status,
    required this.rejectionReason,
    required this.createdAtUtc,
    required this.decidedAtUtc,
    this.decidedBy,
  });

  final int id;
  final String employeeName;
  final double amount;
  final String category;
  final String description;
  final ReimbursementStatus status;
  final String? rejectionReason;
  final DateTime createdAtUtc;
  final DateTime? decidedAtUtc;

  /// Quién decidió: nombre del aprobador o "Sistema" en la aprobación automática.
  final String? decidedBy;

  factory Reimbursement.fromJson(Map<String, dynamic> json) => Reimbursement(
        id: json['id'] as int,
        employeeName: json['employeeName'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        description: json['description'] as String,
        status: ReimbursementStatus.fromApi(json['status'] as String),
        rejectionReason: json['rejectionReason'] as String?,
        createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
        decidedAtUtc: json['decidedAtUtc'] == null
            ? null
            : DateTime.parse(json['decidedAtUtc'] as String),
        decidedBy: json['decidedBy'] as String?,
      );

  /// Código legible para el usuario, p. ej. RB-2026-0007.
  String get code => 'RB-${createdAtUtc.year}-${id.toString().padLeft(4, '0')}';

  bool get exceedsAutoApprovalLimit => amount > autoApprovalLimit;
}
