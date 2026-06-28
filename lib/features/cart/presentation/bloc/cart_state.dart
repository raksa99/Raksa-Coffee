import 'package:equatable/equatable.dart';
import '../../domain/models/cart_item.dart';
import '../../../checkout/domain/models/order.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final DiscountType discountType;
  final double discountValue;
  final double taxRate;
  final List<Order> queuedOrders;
  final String? errorMessage;
  final bool isSuccess;

  const CartState({
    this.items = const [],
    this.discountType = DiscountType.percentage,
    this.discountValue = 0.0,
    this.taxRate = 0.08, // 8% default tax rate
    this.queuedOrders = const [],
    this.errorMessage,
    this.isSuccess = false,
  });

  // Calculate pricing metrics
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get discountAmount {
    if (discountType == DiscountType.percentage) {
      return subtotal * (discountValue / 100);
    } else {
      return discountValue;
    }
  }

  double get taxAmount {
    final taxable = subtotal - discountAmount;
    return taxable * taxRate;
  }

  double get total {
    final base = subtotal - discountAmount;
    return base + taxAmount;
  }

  CartState copyWith({
    List<CartItem>? items,
    DiscountType? discountType,
    double? discountValue,
    double? taxRate,
    List<Order>? queuedOrders,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CartState(
      items: items ?? this.items,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxRate: taxRate ?? this.taxRate,
      queuedOrders: queuedOrders ?? this.queuedOrders,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
        items,
        discountType,
        discountValue,
        taxRate,
        queuedOrders,
        errorMessage,
        isSuccess,
      ];
}
