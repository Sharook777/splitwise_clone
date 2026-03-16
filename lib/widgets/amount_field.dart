import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color themeColor;

  const AmountField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.themeColor,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant AmountField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_focusNode.hasFocus) {
      String newText = _format(widget.value);
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  String _format(double v) {
    if (v == 0) return '';
    return v % 1 == 0 ? v.toInt().toString() : v.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}(\.?\d{0,2})')),
        ],
        style: TextStyle(fontSize: 14, height: 1, color: widget.themeColor),
        decoration: InputDecoration(
          isDense: true,
          hintText: '0',
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
        ),
        onChanged: (val) {
          widget.onChanged(double.tryParse(val) ?? 0);
        },
      ),
    );
  }
}
