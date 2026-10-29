import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../theme/app_theme.dart';

extension ReimbursementStatusStyle on ReimbursementStatus {
  String get label => switch (this) {
        ReimbursementStatus.pending => 'Pendiente',
        ReimbursementStatus.approved => 'Aprobada',
        ReimbursementStatus.rejected => 'Rechazada',
      };

  Color get color => switch (this) {
        ReimbursementStatus.pending => AppColors.pending,
        ReimbursementStatus.approved => AppColors.approved,
        ReimbursementStatus.rejected => AppColors.rejected,
      };

  Color get background => switch (this) {
        ReimbursementStatus.pending => AppColors.pendingBg,
        ReimbursementStatus.approved => AppColors.approvedBg,
        ReimbursementStatus.rejected => AppColors.rejectedBg,
      };

  IconData get icon => switch (this) {
        ReimbursementStatus.pending => Icons.schedule_rounded,
        ReimbursementStatus.approved => Icons.check_rounded,
        ReimbursementStatus.rejected => Icons.close_rounded,
      };
}

/// Icono del estado dentro de un círculo de color sólido.
class StatusDot extends StatelessWidget {
  const StatusDot(this.status, {super.key, this.size = 16});

  final ReimbursementStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
      child: Icon(status.icon, size: size * 0.7, color: Colors.white),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final ReimbursementStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(status),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
