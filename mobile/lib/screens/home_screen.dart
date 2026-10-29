import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/reimbursement.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/brand.dart';
import '../widgets/primary_button.dart';
import '../widgets/reimbursement_card.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onCreate,
    required this.onSeeAll,
  });

  final List<Reimbursement> items;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          const BrandHeader(),
          const SizedBox(height: 28),
          const Text('¡Hola, ${ApiConfig.employeeName}!', style: AppText.pageTitle),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(right: 70),
            child: Text(
              'Gestiona aquí tus gastos de trabajo y solicita el reembolso de forma rápida y sencilla.',
              style: AppText.subtitle,
            ),
          ),
          const SizedBox(height: 24),
          if (error != null)
            ErrorView(message: error!, onRetry: onRefresh)
          else if (loading && items.isEmpty)
            const LoadingView()
          else ...[
            _SummaryCard(items: items),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Registrar gasto', icon: Icons.add_rounded, onPressed: onCreate),
            const SizedBox(height: 18),
            _RecentActivity(items: items, onSeeAll: onSeeAll),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});

  final List<Reimbursement> items;

  int _count(ReimbursementStatus status) => items.where((i) => i.status == status).length;

  @override
  Widget build(BuildContext context) {
    final approvedTotal = items
        .where((i) => i.status == ReimbursementStatus.approved)
        .fold<double>(0, (sum, i) => sum + i.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen de mis solicitudes', style: AppText.sectionTitle),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final status in ReimbursementStatus.values) ...[
                Expanded(child: _StatTile(status: status, count: _count(status))),
                if (status != ReimbursementStatus.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.purpleBg, shape: BoxShape.circle),
                  child: const Icon(Icons.savings_rounded, color: AppColors.purple, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monto total aprobado',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: formatCopNumber(approvedTotal),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                            children: const [
                              TextSpan(
                                text: ' COP',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.status, required this.count});

  final ReimbursementStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: status.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusDot(status, size: 30),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.navy, height: 1.1),
          ),
          Text(
            count == 1 ? status.label : '${status.label}s',
            style: const TextStyle(fontSize: 12.5, color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.items, required this.onSeeAll});

  final List<Reimbursement> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Actividad reciente', style: AppText.sectionTitle),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver todas'),
                    Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (items.isEmpty)
            const EmptyView(message: 'Aún no tienes solicitudes.\nRegistra tu primer gasto.')
          else
            for (final item in items.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReimbursementCard(item: item, compact: true),
              ),
        ],
      ),
    );
  }
}
