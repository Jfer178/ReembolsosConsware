import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../theme/app_theme.dart';
import '../widgets/reimbursement_card.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';

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

  List<Reimbursement> get _visibleItems {
    final query = _query.trim().toLowerCase();
    return widget.items.where((item) {
      if (_filter != null && item.status != _filter) return false;
      if (query.isEmpty) return true;
      return item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'Mis solicitudes',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          const Text(
            'Revisa el estado de tus solicitudes de reembolso.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar por descripción, categoría o código',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todas (${widget.items.length})',
                  selected: _filter == null,
                  onSelected: () => setState(() => _filter = null),
                ),
                for (final status in ReimbursementStatus.values)
                  _FilterChip(
                    label: '${status.label}s (${widget.items.where((i) => i.status == status).length})',
                    selected: _filter == status,
                    onSelected: () => setState(() => _filter = status),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                padding: const EdgeInsets.only(bottom: 12),
                child: ReimbursementCard(item: item),
              ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
