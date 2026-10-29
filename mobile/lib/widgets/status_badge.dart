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
        ReimbursementStatus.pending => Icons.schedule,
        ReimbursementStatus.approved => Icons.check_circle,
        ReimbursementStatus.rejected => Icons.cancel,
      };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final ReimbursementStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
