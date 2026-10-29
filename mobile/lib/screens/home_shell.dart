import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/reimbursement.dart';
import '../services/reimbursement_api_service.dart';
import '../theme/app_theme.dart';
import 'create_reimbursement_screen.dart';
import 'home_screen.dart';
import 'my_reimbursements_screen.dart';

/// Carga las solicitudes del empleado una sola vez y las comparte con las pestañas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.service});

  final ReimbursementApiService service;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  List<Reimbursement> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.service.getMyReimbursements(ApiConfig.employeeName);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<Reimbursement>(
      MaterialPageRoute(builder: (_) => CreateReimbursementScreen(service: widget.service)),
    );
    if (created == null || !mounted) return;

    final message = created.status == ReimbursementStatus.approved
        ? 'Solicitud ${created.code} aprobada automáticamente.'
        : 'Solicitud ${created.code} enviada. Queda pendiente de aprobación.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    setState(() => _tab = 1);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(
              items: _items,
              loading: _loading,
              error: _error,
              onRefresh: _load,
              onCreate: _openCreate,
              onSeeAll: () => setState(() => _tab = 1),
            ),
            MyReimbursementsScreen(
              items: _items,
              loading: _loading,
              error: _error,
              onRefresh: _load,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        tooltip: 'Registrar gasto',
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: 'Inicio',
                icon: Icons.home_rounded,
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
            ),
            const SizedBox(width: 72),
            Expanded(
              child: _NavItem(
                label: 'Mis solicitudes',
                icon: Icons.description_rounded,
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
