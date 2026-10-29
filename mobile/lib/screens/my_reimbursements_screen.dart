import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/reimbursement_card.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';

enum _SortOrder {
  newest('Más recientes'),
  oldest('Más antiguas'),
  highest('Mayor monto'),
  lowest('Menor monto');

  const _SortOrder(this.label);

  final String label;
}

class MyReimbursementsScreen extends StatefulWidget {
  const MyReimbursementsScreen({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  final List<Reimbursement> items;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  @override
  State<MyReimbursementsScreen> createState() => _MyReimbursementsScreenState();
}

class _MyReimbursementsScreenState extends State<MyReimbursementsScreen> {
  ReimbursementStatus? _filter; // null = todas
  String _query = '';
  _SortOrder _sort = _SortOrder.newest;

  List<Reimbursement> get _visibleItems {
    final query = _query.trim().toLowerCase();
    final result = widget.items.where((item) {
      if (_filter != null && item.status != _filter) return false;
      if (query.isEmpty) return true;
      return item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query);
    }).toList();

    result.sort(switch (_sort) {
      _SortOrder.newest => (a, b) => b.createdAtUtc.compareTo(a.createdAtUtc),
      _SortOrder.oldest => (a, b) => a.createdAtUtc.compareTo(b.createdAtUtc),
      _SortOrder.highest => (a, b) => b.amount.compareTo(a.amount),
      _SortOrder.lowest => (a, b) => a.amount.compareTo(b.amount),
    });
    return result;
  }

  int _count(ReimbursementStatus status) => widget.items.where((i) => i.status == status).length;

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
        children: [
          const BrandHeader(),
          const SizedBox(height: 28),
          const Text('Mis solicitudes', style: AppText.pageTitle),
          const SizedBox(height: 6),
          const Text('Revisa el estado de tus solicitudes de reembolso.', style: AppText.subtitle),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: cardDecoration(radius: 18),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por descripción, categoría o código...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas (${widget.items.length})',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final status in ReimbursementStatus.values)
                  _FilterChip(
                    label: '${status.label}s (${_count(status)})',
                    selected: _filter == status,
                    onTap: () => setState(() => _filter = status),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: _SortButton(
              value: _sort,
              onChanged: (value) => setState(() => _sort = value),
            ),
          ),
          const SizedBox(height: 14),
          if (widget.error != null)
            ErrorView(message: widget.error!, onRetry: widget.onRefresh)
          else if (widget.loading && widget.items.isEmpty)
            const LoadingView()
          else if (visible.isEmpty)
            EmptyView(
              message: widget.items.isEmpty
                  ? 'Aún no tienes solicitudes.'
                  : 'No hay solicitudes que coincidan con la búsqueda.',
            )
          else
            for (final item in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ReimbursementCard(item: item),
              ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: selected ? Colors.transparent : AppColors.border),
              boxShadow: selected ? AppShadows.button : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : AppColors.text,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onChanged});

  final _SortOrder value;
  final ValueChanged<_SortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortOrder>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Ordenar',
      color: Colors.white,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        for (final order in _SortOrder.values)
          PopupMenuItem(
            value: order,
            child: Text(
              order.label,
              style: TextStyle(
                fontWeight: order == value ? FontWeight.w600 : FontWeight.w400,
                color: order == value ? AppColors.primary : AppColors.text,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.navy),
            const SizedBox(width: 8),
            Text(value.label, style: const TextStyle(fontSize: 13, color: AppColors.navy)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.navy),
          ],
        ),
      ),
    );
  }
}
