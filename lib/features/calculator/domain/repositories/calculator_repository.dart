import '../entities/calculator_state_entity.dart';

abstract class CalculatorRepository {
  CalculatorStateEntity inputDigit(CalculatorStateEntity state, String digit);
  CalculatorStateEntity inputDecimal(CalculatorStateEntity state);
  CalculatorStateEntity inputOperator(
    CalculatorStateEntity state,
    String operator,
  );
  CalculatorStateEntity calculate(CalculatorStateEntity state);
  CalculatorStateEntity clear();
  CalculatorStateEntity toggleSign(CalculatorStateEntity state);
  CalculatorStateEntity percentage(CalculatorStateEntity state);
}
