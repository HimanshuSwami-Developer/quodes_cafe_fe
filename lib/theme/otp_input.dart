import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'theme.dart';

/// Six single-digit boxes. Pasting the whole code into any box fills all six.
class OtpInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  const OtpInput({super.key, required this.onChanged, this.onCompleted});
  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _digits) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final code = _digits.map((c) => c.text).join();
    widget.onChanged(code);
    if (code.length == 6) widget.onCompleted?.call(code);
  }

  Widget _box(int i) => SizedBox(
    width: 48,
    height: 56,
    child: TextField(
      controller: _digits[i],
      focusNode: _nodes[i],
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: i == 0 ? 6 : 1,
      style: display(22, weight: FontWeight.w700),
      decoration: InputDecoration(
        counterText: '',
        contentPadding: EdgeInsets.zero,
        semanticCounterText: 'Digit ${i + 1}',
        fillColor: _digits[i].text.isNotEmpty ? Q.surfaceHi : Q.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _digits[i].text.isNotEmpty ? Q.primary : Q.borderHi,
          ),
        ),
      ),
      onChanged: (v) {
        if (v.length > 1) {
          for (var k = 0; k < 6; k++) {
            _digits[k].text = k < v.length ? v[k] : '';
          }
          _nodes[5].requestFocus();
        } else if (v.isNotEmpty && i < 5) {
          _nodes[i + 1].requestFocus();
        } else if (v.isEmpty && i > 0) {
          _nodes[i - 1].requestFocus();
        }
        setState(() {});
        _emit();
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(6, _box),
  );
}
