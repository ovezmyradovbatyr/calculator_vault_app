import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/calculator_state_entity.dart';
import '../../domain/usecases/calculator_usecases.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorBlocState> {
  final InputDigit inputDigit;
  final InputDecimal inputDecimal;
  final InputOperator inputOperator;
  final Calculate calculate;
  final Clear clear;
  final ToggleSign toggleSign;
  final Percentage percentage;

  CalculatorBloc({
    required this.inputDigit,
    required this.inputDecimal,
    required this.inputOperator,
    required this.calculate,
    required this.clear,
    required this.toggleSign,
    required this.percentage,
  }) : super(CalculatorBlocState(const CalculatorStateEntity(display: '0'))) {
    on<DigitPressed>((event, emit) {
      emit(CalculatorBlocState(inputDigit(state.entity, event.digit)));
    });

    on<DecimalPressed>((event, emit) {
      emit(CalculatorBlocState(inputDecimal(state.entity)));
    });

    on<OperatorPressed>((event, emit) {
      emit(CalculatorBlocState(inputOperator(state.entity, event.operator)));
    });

    on<EqualsPressed>((event, emit) {
      emit(CalculatorBlocState(calculate(state.entity)));
    });

    on<ClearPressed>((event, emit) {
      emit(CalculatorBlocState(clear()));
    });

    on<ToggleSignPressed>((event, emit) {
      emit(CalculatorBlocState(toggleSign(state.entity)));
    });

    on<PercentagePressed>((event, emit) {
      emit(CalculatorBlocState(percentage(state.entity)));
    });
  }
}
