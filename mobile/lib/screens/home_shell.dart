import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../models/session.dart';
import '../services/reimbursement_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import '../widgets/brand.dart';
import 'create_reimbursement_screen.dart';
import 'home_screen.dart';
import 'my_reimbursements_screen.dart';

/// Carga las solicitudes del empleado una sola vez y las comparte con las pestañas.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.service,
    required this.session,
    required this.onLogout,
    required this.onSessionExpired,
  });

  final ReimbursementApiService service;
  final Session session;
  final VoidCallback onLogout;
  final VoidCallback onSessionExpired;

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
      final items = await widget.service.getMyReimbursements();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on SessionExpiredException {
      if (mounted) widget.onSessionExpired();
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
      FadeSlideRoute(builder: (_) => CreateReimbursementScreen(service: widget.service)),
    );
    if (created == null || !mounted) return;

    // El formulario ya mostró la animación de éxito; aquí solo se lleva al listado actualizado.
    setState(() => _tab = 1);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              HomeScreen(
                session: widget.session,
                onLogout: widget.onLogout,
                items: _items,
                loading: _loading,
                error: _error,
                onRefresh: _load,
                onCreate: _openCreate,
                onSeeAll: () => setState(() => _tab = 1),
              ),
              MyReimbursementsScreen(
                session: widget.session,
                onLogout: widget.onLogout,
                items: _items,
                loading: _loading,
                error: _error,
                onRefresh: _load,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _CreateButton(onPressed: _openCreate),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        selected: _tab,
        onSelected: (index) => setState(() => _tab = index),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Registrar gasto',
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: AppShadows.button,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  key: const Key('nav-home'),
                  label: 'Inicio',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  selected: selected == 0,
                  onTap: () => onSelected(0),
                ),
              ),
              const SizedBox(width: 90),
              Expanded(
                child: _NavItem(
                  key: const Key('nav-requests'),
                  label: 'Mis solicitudes',
                  icon: Icons.description_outlined,
                  selectedIcon: Icons.description_rounded,
                  selected: selected == 1,
                  onTap: () => onSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 26),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 18 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
