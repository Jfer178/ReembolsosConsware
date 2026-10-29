import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import 'reimbursement_detail_sheet.dart';
import 'status_badge.dart';

class ReimbursementCard extends StatelessWidget {
  const ReimbursementCard({super.key, required this.item});

  final Reimbursement item;

  @override
  Widget build(BuildContext context) {
    final showManualReview =
        item.status == ReimbursementStatus.pending && item.exceedsAutoApprovalLimit;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showReimbursementDetail(context, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryAvatar(category: item.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.category} - ${item.description}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.code} · ${formatDate(item.createdAtUtc)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCop(item.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(item.status),
                    ],
                  ),
                ],
              ),
              if (item.status == ReimbursementStatus.rejected && item.rejectionReason != null) ...[
                const SizedBox(height: 12),
                RejectionReasonBox(reason: item.rejectionReason!),
              ],
              if (showManualReview) ...[
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.pending),
                      SizedBox(width: 4),
                      Text(
                        'Requiere aprobación manual',
                        style: TextStyle(fontSize: 11, color: AppColors.pending),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconForCategory(category), color: AppColors.text),
    );
  }
}

class RejectionReasonBox extends StatelessWidget {
  const RejectionReasonBox({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel, color: AppColors.rejected, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motivo del rechazo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.rejected),
                ),
                const SizedBox(height: 2),
                Text(reason, style: const TextStyle(fontSize: 12, color: AppColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
