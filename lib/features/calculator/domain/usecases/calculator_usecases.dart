import '../entities/calculator_state_entity.dart';
import '../repositories/calculator_repository.dart';

class InputDigit {
  final CalculatorRepository repository;
  InputDigit(this.repository);

  CalculatorStateEntity call(CalculatorStateEntity state, String digit) =>
      repository.inputDigit(state, digit);
}

class InputDecimal {
  final CalculatorRepository repository;
  InputDecimal(this.repository);

  CalculatorStateEntity call(CalculatorStateEntity state) =>
      repository.inputDecimal(state);
}

class InputOperator {
  final CalculatorRepository repository;
  InputOperator(this.repository);

  CalculatorStateEntity call(CalculatorStateEntity state, String operator) =>
      repository.inputOperator(state, operator);
}

class Calculate {
  final CalculatorRepository repository;
  Calculate(this.repository);

  CalculatorStateEntity call(CalculatorStateEntity state) =>
      repository.calculate(state);
}

class Clear {
  final CalculatorRepository repository;
  Clear(this.repository);

  CalculatorStateEntity call() => repository.clear();
}

class ToggleSign {
  final CalculatorRepository repository;
  ToggleSign(this.repository);

  CalculatorStateEntity call(CalculatorStateEntity state) =>
      repository.toggleSign(state);
}

class Percentage {
  final CalculatorRepository repository;
  Percentage(this.repository);

  CalculatorStateEntity call(CalculatorStateEntity state) =>
      repository.percentage(state);
}
