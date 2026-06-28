import 'package:equatable/equatable.dart';
import '../../domain/models/cart_item.dart';
import '../../../checkout/domain/models/order.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final CartItem item;

  const AddToCart(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateCartItemQuantity extends CartEvent {
  final String itemId;
  final int newQuantity;

  const UpdateCartItemQuantity(this.itemId, this.newQuantity);

  @override
  List<Object?> get props => [itemId, newQuantity];
}

class RemoveFromCart extends CartEvent {
  final String itemId;

  const RemoveFromCart(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ClearCart extends CartEvent {}

class ApplyDiscount extends CartEvent {
  final DiscountType discountType;
  final double discountValue;

  const ApplyDiscount(this.discountType, this.discountValue);

  @override
  List<Object?> get props => [discountType, discountValue];
}

class HoldOrder extends CartEvent {
  final String customerName;

  const HoldOrder({this.customerName = ''});

  @override
  List<Object?> get props => [customerName];
}

class ResumeOrder extends CartEvent {
  final Order order;

  const ResumeOrder(this.order);

  @override
  List<Object?> get props => [order];
}

class LoadQueuedOrdersList extends CartEvent {}

class DeleteQueuedOrder extends CartEvent {
  final String orderId;

  const DeleteQueuedOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
