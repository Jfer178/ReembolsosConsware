import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'reimbursement_card.dart';
import 'status_badge.dart';

Future<void> showReimbursementDetail(BuildContext context, Reimbursement item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: _DetailContent(item: item),
      ),
    ),
  );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.item});

  final Reimbursement item;

  @override
  Widget build(BuildContext context) {
    final decidedLabel =
        item.status == ReimbursementStatus.rejected ? 'Rechazada el' : 'Aprobada el';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CategoryAvatar(category: item.category),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.category,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
            ),
            StatusBadge(item.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          formatCop(item.amount),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
        const SizedBox(height: 16),
        _DetailRow(label: 'Código', value: item.code),
        _DetailRow(label: 'Empleado', value: item.employeeName),
        _DetailRow(label: 'Creada el', value: formatDateTime(item.createdAtUtc)),
        if (item.decidedAtUtc != null)
          _DetailRow(label: decidedLabel, value: formatDateTime(item.decidedAtUtc!)),
        const SizedBox(height: 12),
        const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 4),
        Text(item.description, style: const TextStyle(color: AppColors.text)),
        if (item.status == ReimbursementStatus.rejected && item.rejectionReason != null) ...[
          const SizedBox(height: 16),
          RejectionReasonBox(reason: item.rejectionReason!),
        ],
        if (item.status == ReimbursementStatus.pending) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pendingBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Supera \$500.000 COP: está a la espera de la aprobación manual del equipo de finanzas.',
              style: TextStyle(color: AppColors.text, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.text))),
        ],
      ),
    );
  }
}
