import 'package:flutter/services.dart';

const _months = [
  'ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
  'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.',
];

/// "85000" -> "85.000"
String groupThousands(String digits) =>
    digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

/// 85000 -> "$ 85.000 COP"; 500000.01 -> "$ 500.000,01 COP"
String formatCop(num amount) {
  final whole = amount.truncate();
  final cents = ((amount - whole) * 100).round();
  final decimals = cents == 0 ? '' : ',${cents.toString().padLeft(2, '0')}';
  return '\$ ${groupThousands(whole.toString())}$decimals COP';
}

/// Fecha en hora local: "14 ene. 2026"
String formatDate(DateTime utc) {
  final d = utc.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Fecha y hora local: "14 ene. 2026, 09:41"
String formatDateTime(DateTime utc) {
  final d = utc.toLocal();
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${formatDate(utc)}, $hh:$mm';
}

/// "1.250.000" -> 1250000; vacío -> null
int? parseCopInput(String text) {
  final digits = text.replaceAll('.', '');
  return digits.isEmpty ? null : int.tryParse(digits);
}

/// Campo de monto en pesos enteros con separador de miles mientras se escribe.
class CopAmountInputFormatter extends TextInputFormatter {
  static const maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;

    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = digits.isEmpty ? '' : groupThousands(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
