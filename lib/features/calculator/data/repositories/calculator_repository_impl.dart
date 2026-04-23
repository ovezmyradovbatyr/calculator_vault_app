import '../../domain/entities/calculator_state_entity.dart';
import '../../domain/repositories/calculator_repository.dart';

class CalculatorRepositoryImpl implements CalculatorRepository {
  @override
  CalculatorStateEntity clear() {
    return const CalculatorStateEntity(
      display: '0',
      expression: '',
      history: '',
    );
  }

  @override
  CalculatorStateEntity inputDigit(CalculatorStateEntity state, String digit) {
    String newDisplay;
    String newExpression;

    if (state.waitingForSecondOperand) {
      newDisplay = digit;
      // After equals (firstOperand == null): start a brand-new expression.
      // After operator (firstOperand != null): append digit to expression.
      newExpression = state.firstOperand != null
          ? '${state.expression}$digit'
          : digit;
      return state.copyWith(
        display: newDisplay,
        expression: newExpression,
        history: '',
        waitingForSecondOperand: false,
      );
    }

    // Limit input to 9 digits (excluding minus sign and decimal point).
    final digitCount = state.display.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount >= 9) return state;

    newDisplay = state.display == '0' ? digit : state.display + digit;
    // replace last token in expression with updated display
    newExpression = _replaceLastToken(state.expression, newDisplay);
    return state.copyWith(
      display: newDisplay,
      expression: newExpression,
      history: '',
    );
  }

  @override
  CalculatorStateEntity inputDecimal(CalculatorStateEntity state) {
    if (state.waitingForSecondOperand) {
      return state.copyWith(
        display: '0.',
        expression: '${state.expression}0.',
        history: '',
        waitingForSecondOperand: false,
      );
    }
    if (!state.display.contains('.')) {
      final newDisplay = '${state.display}.';
      final newExpression = _replaceLastToken(state.expression, newDisplay);
      return state.copyWith(
        display: newDisplay,
        expression: newExpression,
        history: '',
      );
    }
    return state;
  }

  @override
  CalculatorStateEntity inputOperator(
    CalculatorStateEntity state,
    String operator,
  ) {
    final current = double.tryParse(state.display) ?? 0;
    // If already waiting for second operand, just replace the operator
    if (state.waitingForSecondOperand && state.firstOperand != null) {
      final expr = state.expression;
      final newExpression = expr.isNotEmpty
          ? '${expr.substring(0, expr.length - 1)}$operator'
          : '${state.display}$operator';
      return state.copyWith(expression: newExpression, operator: operator);
    }
    if (state.firstOperand != null && !state.waitingForSecondOperand) {
      final result = _compute(state.firstOperand!, current, state.operator!);
      final display = _formatResult(result);
      final newExpression = '${_formatResult(result)}$operator';
      return CalculatorStateEntity(
        display: display,
        expression: newExpression,
        history: '',
        firstOperand: result,
        operator: operator,
        waitingForSecondOperand: true,
      );
    }
    final newExpression = state.expression.isEmpty
        ? '${state.display}$operator'
        : '${state.expression}$operator';
    return CalculatorStateEntity(
      display: state.display,
      expression: newExpression,
      history: '',
      firstOperand: current,
      operator: operator,
      waitingForSecondOperand: true,
    );
  }

  @override
  CalculatorStateEntity calculate(CalculatorStateEntity state) {
    if (state.firstOperand == null || state.operator == null) return state;
    // No second operand entered yet — do nothing
    if (state.waitingForSecondOperand) return state;
    final second = double.tryParse(state.display) ?? 0;
    final result = _compute(state.firstOperand!, second, state.operator!);
    final resultStr = _formatResult(result);
    // history = full expression that was computed
    final historyExpr = state.expression.isEmpty
        ? '${_formatResult(state.firstOperand!)}${state.operator}${state.display}'
        : state.expression;
    return CalculatorStateEntity(
      display: resultStr,
      expression: resultStr,
      history: '$historyExpr=',
      // Mark as afterEquals: next digit starts fresh, next operator chains
      waitingForSecondOperand: true,
    );
  }

  @override
  CalculatorStateEntity toggleSign(CalculatorStateEntity state) {
    final value = double.tryParse(state.display) ?? 0;
    final newDisplay = _formatResult(-value);
    final newExpression = _replaceLastToken(state.expression, newDisplay);
    return state.copyWith(display: newDisplay, expression: newExpression);
  }

  @override
  CalculatorStateEntity percentage(CalculatorStateEntity state) {
    final value = double.tryParse(state.display) ?? 0;
    final newDisplay = _formatResult(value / 100);
    final newExpression = _replaceLastToken(state.expression, newDisplay);
    return state.copyWith(display: newDisplay, expression: newExpression);
  }

  /// Replaces the last numeric token in expression with [newToken].
  String _replaceLastToken(String expression, String newToken) {
    if (expression.isEmpty) return newToken;
    final ops = ['+', '-', '×', '÷'];
    int lastOp = -1;
    for (int i = expression.length - 1; i >= 0; i--) {
      if (ops.contains(expression[i])) {
        // A '-' at position 0 or right after another operator is a unary
        // minus (part of a negative number), not a binary operator — skip it.
        if (expression[i] == '-' &&
            (i == 0 || ops.contains(expression[i - 1]))) {
          continue;
        }
        lastOp = i;
        break;
      }
    }
    if (lastOp == -1) return newToken;
    return '${expression.substring(0, lastOp + 1)}$newToken';
  }

  double _compute(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b != 0 ? a / b : double.nan;
      default:
        return b;
    }
  }

  String _formatResult(double value) {
    if (value.isNaN) return 'Error';
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return double.parse(value.toStringAsFixed(10)).toString();
  }
}
