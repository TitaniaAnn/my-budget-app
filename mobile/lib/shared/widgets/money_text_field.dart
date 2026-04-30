// A TextFormField specialised for money input.
//
// Adds the leading "$" prefix, restricts input to digits + a single 2-decimal
// fractional part, and exposes a numeric-decimal keyboard. Callers parse the
// resulting text via [parseToCents] from core/utils/money.dart.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MoneyTextField extends StatelessWidget {
  const MoneyTextField({
    super.key,
    required this.controller,
    this.hintText = '0.00',
    this.validator,
    this.style,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final TextStyle? style;

  static final _moneyFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'));

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_moneyFormatter],
      decoration: InputDecoration(prefixText: r'$', hintText: hintText),
      style: style,
      validator: validator,
    );
  }
}
