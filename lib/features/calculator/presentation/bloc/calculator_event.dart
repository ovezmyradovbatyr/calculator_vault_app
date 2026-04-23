import 'package:equatable/equatable.dart';

abstract class CalculatorEvent extends Equatable {
  const CalculatorEvent();
  @override
  List<Object?> get props => [];
}

class DigitPressed extends CalculatorEvent {
  final String digit;
  const DigitPressed(this.digit);
  @override
  List<Object?> get props => [digit];
}

class DecimalPressed extends CalculatorEvent {
  const DecimalPressed();
}

class OperatorPressed extends CalculatorEvent {
  final String operator;
  const OperatorPressed(this.operator);
  @override
  List<Object?> get props => [operator];
}

class EqualsPressed extends CalculatorEvent {
  const EqualsPressed();
}

class ClearPressed extends CalculatorEvent {
  const ClearPressed();
}

class ToggleSignPressed extends CalculatorEvent {
  const ToggleSignPressed();
}

class PercentagePressed extends CalculatorEvent {
  const PercentagePressed();
}
