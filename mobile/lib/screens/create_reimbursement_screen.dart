import 'package:flutter/material.dart';

import '../models/reimbursement.dart';
import '../services/reimbursement_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../widgets/animations.dart';
import '../widgets/brand.dart';
import '../widgets/primary_button.dart';
import '../widgets/state_views.dart';

class CreateReimbursementScreen extends StatefulWidget {
  const CreateReimbursementScreen({super.key, required this.service});

  final ReimbursementApiService service;

  @override
  State<CreateReimbursementScreen> createState() => _CreateReimbursementScreenState();
}

class _CreateReimbursementScreenState extends State<CreateReimbursementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _category;
  bool _submitting = false;
  bool _showPolicyBanner = true;
  String? _submitError;

  int? get _amount => parseCopInput(_amountController.text);

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitError = null);
    // Si el formulario es inválido no se llama a la API.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final created = await widget.service.createReimbursement(
        amount: _amount!,
        category: _category!,
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(item: created),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount ?? 0;
    final categoryIcon = _category == null ? Icons.category_outlined : iconForCategory(_category!);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.of(context).maybePop()),
                    const Expanded(child: Center(child: ConswareLogo(height: 26))),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Registrar gasto', style: AppText.pageTitle),
                const SizedBox(height: 16),
                if (_showPolicyBanner)
                  _PolicyBanner(onClose: () => setState(() => _showPolicyBanner = false)),
                const _FieldLabel('Monto'),
                TextFormField(
                  controller: _amountController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CopAmountInputFormatter()],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixIcon: Container(
                      width: 56,
                      margin: const EdgeInsets.only(right: 12),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.border)),
                      ),
                      child: const Text(
                        '\$',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy),
                      ),
                    ),
                    suffixText: 'COP',
                    suffixStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  validator: (_) {
                    final value = _amount;
                    if (value == null) return 'Ingresa el monto del gasto.';
                    if (value <= 0) return 'El monto debe ser mayor a cero.';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                if (amount > Reimbursement.autoApprovalLimit)
                  const _AmountHint(
                    icon: Icons.schedule_rounded,
                    color: AppColors.pending,
                    text: 'Supera \$500.000 COP: quedará pendiente de aprobación manual.',
                  )
                else if (amount > 0)
                  const _AmountHint(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.approved,
                    text: 'Hasta \$500.000 COP: se aprueba automáticamente.',
                  ),
                const _FieldLabel('Categoría'),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  hint: const Text('Selecciona una categoría', style: TextStyle(fontSize: 14)),
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, color: AppColors.text),
                  decoration: InputDecoration(
                    prefixIcon: Icon(categoryIcon, color: AppColors.navy),
                  ),
                  selectedItemBuilder: (_) => [
                    for (final category in expenseCategories) Text(category.name),
                  ],
                  items: [
                    for (final category in expenseCategories)
                      DropdownMenuItem(
                        value: category.name,
                        child: Row(
                          children: [
                            Icon(category.icon, size: 20, color: AppColors.navy),
                            const SizedBox(width: 12),
                            Text(category.name),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _submitting ? null : (value) => setState(() => _category = value),
                  validator: (value) => value == null ? 'Selecciona una categoría.' : null,
                ),
                const _FieldLabel('Descripción'),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_submitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14.5, height: 1.45),
                  decoration: const InputDecoration(
                    hintText: 'Ej.: Traslado al cliente para la reunión de presentación del proyecto.',
                    hintMaxLines: 2,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Describe el gasto.' : null,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 8),
                  ErrorBanner(message: _submitError!),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Enviar solicitud',
                  icon: Icons.send_rounded,
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmación animada después de enviar: check que se dibuja y el resultado de la regla.
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.item});

  final Reimbursement item;

  @override
  Widget build(BuildContext context) {
    final approved = item.status == ReimbursementStatus.approved;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SuccessCheck(color: approved ? AppColors.approved : AppColors.primary),
            const SizedBox(height: 22),
            FadeSlideIn(
              index: 2,
              child: Text(
                approved ? '¡Aprobada automáticamente!' : '¡Solicitud enviada!',
                textAlign: TextAlign.center,
                style: AppText.sectionTitle.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              index: 3,
              child: Text(
                approved
                    ? '${item.code} por ${formatCop(item.amount)} quedó aprobada al estar dentro del límite.'
                    : '${item.code} por ${formatCop(item.amount)} quedó pendiente de revisión del Equipo de Finanzas.',
                textAlign: TextAlign.center,
                style: AppText.subtitle,
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              index: 4,
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Ver mis solicitudes',
                  icon: Icons.receipt_long_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppShadows.card,
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Volver',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.navy),
      ),
    );
  }
}

class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF7EC), Color(0xFFFFEEDD)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDDB8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFFFF9A1F), shape: BoxShape.circle),
            child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Las solicitudes con un monto superior a \$500.000 COP requieren aprobación manual del equipo de finanzas.',
              style: TextStyle(fontSize: 12.5, color: AppColors.text, height: 1.45),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 2),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy),
          children: const [
            TextSpan(text: ' *', style: TextStyle(color: AppColors.rejected)),
          ],
        ),
      ),
    );
  }
}

class _AmountHint extends StatelessWidget {
  const _AmountHint({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }
}
