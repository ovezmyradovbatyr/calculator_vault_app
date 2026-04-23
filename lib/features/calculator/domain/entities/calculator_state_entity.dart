import 'package:equatable/equatable.dart';

class CalculatorStateEntity extends Equatable {
  final String display;
  final String expression;
  final String history;
  final double? firstOperand;
  final String? operator;
  final bool waitingForSecondOperand;

  const CalculatorStateEntity({
    required this.display,
    this.expression = '',
    this.history = '',
    this.firstOperand,
    this.operator,
    this.waitingForSecondOperand = false,
  });

  CalculatorStateEntity copyWith({
    String? display,
    String? expression,
    String? history,
    double? firstOperand,
    String? operator,
    bool? waitingForSecondOperand,
    bool clearFirstOperand = false,
    bool clearOperator = false,
  }) {
    return CalculatorStateEntity(
      display: display ?? this.display,
      expression: expression ?? this.expression,
      history: history ?? this.history,
      firstOperand: clearFirstOperand
          ? null
          : (firstOperand ?? this.firstOperand),
      operator: clearOperator ? null : (operator ?? this.operator),
      waitingForSecondOperand:
          waitingForSecondOperand ?? this.waitingForSecondOperand,
    );
  }

  @override
  List<Object?> get props => [
    display,
    expression,
    history,
    firstOperand,
    operator,
    waitingForSecondOperand,
  ];
}
