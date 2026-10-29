import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/reimbursement.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const _Header(),
          const SizedBox(height: 24),
          const Text(
            '¡Hola!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gestiona aquí tus gastos de trabajo y solicita el reembolso de forma rápida y sencilla.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (error != null)
            ErrorView(message: error!, onRetry: onRefresh)
          else if (loading && items.isEmpty)
            const LoadingView()
          else ...[
            _SummaryCard(items: items),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Registrar gasto', icon: Icons.add, onPressed: onCreate),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Actividad reciente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const Spacer(),
                TextButton(onPressed: onSeeAll, child: const Text('Ver todas')),
              ],
            ),
            if (items.isEmpty)
              const EmptyView(message: 'Aún no tienes solicitudes.\nRegistra tu primer gasto.')
            else
              for (final item in items.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ReimbursementCard(item: item),
                ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text(
          'Consware',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const Spacer(),
        Tooltip(
          message: ApiConfig.employeeName,
          child: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Text(
              'ED',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
        ),
      ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de mis solicitudes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final status in ReimbursementStatus.values) ...[
                Expanded(child: _StatTile(status: status, count: _count(status))),
                if (status != ReimbursementStatus.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monto total aprobado', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  Text(
                    formatCop(approvedTotal),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                ],
              ),
            ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, color: status.color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          Text(
            count == 1 ? status.label : '${status.label}s',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
