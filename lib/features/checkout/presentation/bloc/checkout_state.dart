import 'package:equatable/equatable.dart';
import '../../domain/models/order.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutProcessing extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final Order order;

  const CheckoutSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class CheckoutFailure extends CheckoutState {
  final String message;

  const CheckoutFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class SalesHistoryLoaded extends CheckoutState {
  final List<Order> sales;

  const SalesHistoryLoaded(this.sales);

  @override
  List<Object?> get props => [sales];
}
