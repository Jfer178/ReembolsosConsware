import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import 'reimbursement_detail_sheet.dart';
import 'status_badge.dart';

class ReimbursementCard extends StatelessWidget {
  const ReimbursementCard({super.key, required this.item, this.compact = false});

  final Reimbursement item;

  /// Versión para "Actividad reciente": borde fino en vez de sombra y sin código ni motivo.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final showManualReview =
        item.status == ReimbursementStatus.pending && item.exceedsAutoApprovalLimit;
    final showReason = !compact &&
        item.status == ReimbursementStatus.rejected &&
        item.rejectionReason != null;
    final radius = BorderRadius.circular(compact ? 16 : 20);

    return DecoratedBox(
      decoration: compact
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
              border: Border.all(color: AppColors.border),
            )
          : cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: () => showReimbursementDetail(context, item),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, compact ? 12 : 14, 6, compact ? 12 : 14),
            child: Column(
              children: [
                Row(
                  children: [
                    CategoryAvatar(category: item.category),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.category} - ${item.description}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (!compact)
                            Text(
                              item.code,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                            ),
                          Text(
                            formatDate(item.createdAtUtc),
                            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
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
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(item.status),
                        if (showManualReview && !compact) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Requiere aprobación manual',
                            style: TextStyle(fontSize: 10.5, color: AppColors.pending),
                          ),
                        ],
                      ],
                    ),
                    Icon(
                      showReason ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
                if (showReason) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: RejectionReasonBox(reason: item.rejectionReason!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 50});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(iconForCategory(category), color: AppColors.navy, size: size * 0.5),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusDot(ReimbursementStatus.rejected, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motivo del rechazo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.rejected,
                  ),
                ),
                const SizedBox(height: 2),
                Text(reason, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
