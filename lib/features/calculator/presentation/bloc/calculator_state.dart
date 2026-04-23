import 'package:equatable/equatable.dart';
import '../../domain/entities/calculator_state_entity.dart';

class CalculatorBlocState extends Equatable {
  final CalculatorStateEntity entity;

  const CalculatorBlocState(this.entity);

  @override
  List<Object?> get props => [entity];
}
