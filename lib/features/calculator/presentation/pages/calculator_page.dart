import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/calculator_bloc.dart';
import '../bloc/calculator_event.dart';
import '../bloc/calculator_state.dart';
import '../widgets/calc_button.dart';
import '../widgets/calc_display.dart';
import 'secret_vault_page.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const _orange = Color(0xFFFF9F0A);
  static const _darkGray = Color(0xFF1C1C1E);
  static const _lightGray = Color(0xFFA5A5A5);
  static const _midGray = Color(0xFF333333);

  int _equalsCount = 0;
  DateTime? _lastEqualsTime;

  void _onEqualsPressed(CalculatorBloc bloc) {
    final now = DateTime.now();
    if (_lastEqualsTime == null ||
        now.difference(_lastEqualsTime!) > const Duration(seconds: 2)) {
      _equalsCount = 0;
    }
    _lastEqualsTime = now;
    _equalsCount++;

    if (_equalsCount >= 3) {
      _equalsCount = 0;
      _lastEqualsTime = null;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, _) => const SecretVaultPage(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      bloc.add(const EqualsPressed());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkGray,
      body: SafeArea(
        child: BlocBuilder<CalculatorBloc, CalculatorBlocState>(
          builder: (context, state) {
            final bloc = context.read<CalculatorBloc>();
            return LayoutBuilder(
              builder: (context, constraints) {
                const hPad = 16.0;
                const gap = 12.0;
                const rows = 5;
                const cols = 4;
                const bottomPad = 16.0;
                final btnW =
                    (constraints.maxWidth - 2 * hPad - (cols - 1) * gap) / cols;
                final btnH =
                    (constraints.maxHeight * 0.62 -
                        (rows - 1) * gap -
                        bottomPad) /
                    rows;
                final btnSize = min(btnW, btnH);
                return Column(
                  children: [
                    Expanded(
                      child: CalcDisplay(
                        expression: state.entity.expression,
                        history: state.entity.history,
                      ),
                    ),
                    _buildButtonGrid(bloc, btnSize),
                    const SizedBox(height: bottomPad),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtonGrid(CalculatorBloc bloc, double btnSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _row([
            _btn(
              'AC',
              _lightGray,
              Colors.black,
              () => bloc.add(const ClearPressed()),
              btnSize,
            ),
            _btn(
              '+/-',
              _lightGray,
              Colors.black,
              () => bloc.add(const ToggleSignPressed()),
              btnSize,
              debounce: false,
            ),
            _btn(
              '%',
              _lightGray,
              Colors.black,
              () => bloc.add(const PercentagePressed()),
              btnSize,
            ),
            _btn(
              '÷',
              _orange,
              Colors.white,
              () => bloc.add(const OperatorPressed('÷')),
              btnSize,
              paddingBottom: 2,
            ),
          ]),
          const SizedBox(height: 12),
          _row([
            _btn(
              '7',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('7')),
              btnSize,
            ),
            _btn(
              '8',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('8')),
              btnSize,
            ),
            _btn(
              '9',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('9')),
              btnSize,
            ),
            _btn(
              '×',
              _orange,
              Colors.white,
              () => bloc.add(const OperatorPressed('×')),
              btnSize,
              paddingBottom: 2,
            ),
          ]),
          const SizedBox(height: 12),
          _row([
            _btn(
              '4',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('4')),
              btnSize,
            ),
            _btn(
              '5',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('5')),
              btnSize,
            ),
            _btn(
              '6',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('6')),
              btnSize,
            ),
            _btn(
              '-',
              _orange,
              Colors.white,
              () => bloc.add(const OperatorPressed('-')),
              btnSize,
              paddingBottom: 2,
            ),
          ]),
          const SizedBox(height: 12),
          _row([
            _btn(
              '1',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('1')),
              btnSize,
            ),
            _btn(
              '2',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('2')),
              btnSize,
            ),
            _btn(
              '3',
              _midGray,
              Colors.white,
              () => bloc.add(const DigitPressed('3')),
              btnSize,
            ),
            _btn(
              '+',
              _orange,
              Colors.white,
              () => bloc.add(const OperatorPressed('+')),
              btnSize,
              paddingBottom: 2,
            ),
          ]),
          const SizedBox(height: 12),
          // Last row: 0 is wide (2 cells), . and =
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: btnSize,
                  child: _WideZeroButton(
                    onTap: () => bloc.add(const DigitPressed('0')),
                    backgroundColor: _midGray,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: btnSize,
                height: btnSize,
                child: CalcButton(
                  label: '.',
                  backgroundColor: _midGray,
                  onTap: () => bloc.add(const DecimalPressed()),
                  paddingBottom: 2,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: btnSize,
                height: btnSize,
                child: CalcButton(
                  label: '=',
                  backgroundColor: _orange,
                  onTap: () => _onEqualsPressed(bloc),
                  paddingBottom: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: children,
  );

  Widget _btn(
    String label,
    Color bg,
    Color fg,
    VoidCallback onTap,
    double size, {
    double paddingBottom = 0,
    bool debounce = true,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CalcButton(
        label: label,
        backgroundColor: bg,
        textColor: fg,
        onTap: onTap,
        paddingBottom: paddingBottom,
        debounce: debounce,
      ),
    );
  }
}

class _WideZeroButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color backgroundColor;

  const _WideZeroButton({required this.onTap, required this.backgroundColor});

  @override
  State<_WideZeroButton> createState() => _WideZeroButtonState();
}

class _WideZeroButtonState extends State<_WideZeroButton> {
  bool _pressed = false;
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 300)) {
      return;
    }
    _lastTap = now;
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
        decoration: BoxDecoration(
          color: _pressed ? pressedColor : widget.backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 30, bottom: 2),
        child: const Text(
          '0',
          style: TextStyle(fontSize: 28, color: Colors.white),
        ),
      ),
    );
  }
}
