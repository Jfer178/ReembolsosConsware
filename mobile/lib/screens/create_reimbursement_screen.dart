import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/reimbursement.dart';
import '../services/reimbursement_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
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
        employeeName: ApiConfig.employeeName,
        amount: _amount!,
        category: _category!,
        description: _descriptionController.text.trim(),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar gasto')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (_showPolicyBanner)
                _PolicyBanner(onClose: () => setState(() => _showPolicyBanner = false)),
              const _FieldLabel('Monto'),
              TextFormField(
                controller: _amountController,
                enabled: !_submitting,
                keyboardType: TextInputType.number,
                inputFormatters: [CopAmountInputFormatter()],
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: '\$ ',
                  suffixText: 'COP',
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
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.pending,
                  text: 'Supera \$500.000 COP: quedará pendiente de aprobación manual.',
                )
              else if (amount > 0)
                const _AmountHint(
                  icon: Icons.check_circle_outline,
                  color: AppColors.approved,
                  text: 'Hasta \$500.000 COP: se aprueba automáticamente.',
                ),
              const _FieldLabel('Categoría'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                hint: const Text('Selecciona una categoría'),
                borderRadius: BorderRadius.circular(14),
                dropdownColor: Colors.white,
                items: [
                  for (final category in expenseCategories)
                    DropdownMenuItem(
                      value: category.name,
                      child: Row(
                        children: [
                          Icon(category.icon, size: 20, color: AppColors.muted),
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
                decoration: const InputDecoration(
                  hintText: 'Ej.: Taxi al cliente para la reunión de presentación del proyecto.',
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
    );
  }
}

class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.pendingBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: AppColors.pending),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Las solicitudes con un monto superior a \$500.000 COP requieren aprobación manual del equipo de finanzas.',
              style: TextStyle(fontSize: 13, color: AppColors.text, height: 1.35),
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
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
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
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
