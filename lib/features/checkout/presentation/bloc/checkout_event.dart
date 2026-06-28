import 'package:equatable/equatable.dart';
import '../../domain/models/order.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class ProcessPayment extends CheckoutEvent {
  final Order order;
  final PaymentMethod paymentMethod;
  final double amountPaid;

  const ProcessPayment({
    required this.order,
    required this.paymentMethod,
    required this.amountPaid,
  });

  @override
  List<Object?> get props => [order, paymentMethod, amountPaid];
}

class LoadSalesHistory extends CheckoutEvent {}

class ClearSalesHistory extends CheckoutEvent {}
