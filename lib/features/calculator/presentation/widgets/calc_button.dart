import 'package:flutter/material.dart';

class CalcButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final bool wide;
  final double paddingBottom;
  final bool debounce;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.backgroundColor = const Color(0xFF333333),
    this.textColor = Colors.white,
    this.wide = false,
    this.paddingBottom = 0,
    this.debounce = true,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;
  DateTime? _lastTap;

  void _handleTap() {
    if (widget.debounce) {
      final now = DateTime.now();
      if (_lastTap != null &&
          now.difference(_lastTap!) < const Duration(milliseconds: 300)) {
        return;
      }
      _lastTap = now;
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final pressedColor = Color.lerp(
      widget.backgroundColor,
      Colors.white,
      0.35,
    )!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.wide ? double.infinity : null,
        decoration: BoxDecoration(
          color: _pressed ? pressedColor : widget.backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.only(bottom: widget.paddingBottom),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 28,
            color: widget.textColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
