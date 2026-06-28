import 'package:equatable/equatable.dart';
import '../../../cart/domain/models/cart_item.dart';

enum OrderStatus { completed, queued, cancelled }

enum DiscountType { percentage, fixed }

enum PaymentMethod { cash, card, qrCode }

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final List<CartItem> items;
  final DiscountType discountType;
  final double discountValue; // percentage rate or fixed amount
  final double taxRate; // e.g. 0.08 for 8%
  final PaymentMethod? paymentMethod;
  final double amountPaid;
  final DateTime dateTime;
  final OrderStatus status;
  final String customerName;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    this.discountType = DiscountType.percentage,
    this.discountValue = 0.0,
    this.taxRate = 0.08, // Default 8% tax
    this.paymentMethod,
    this.amountPaid = 0.0,
    required this.dateTime,
    this.status = OrderStatus.queued,
    this.customerName = '',
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get discountAmount {
    if (discountType == DiscountType.percentage) {
      return subtotal * (discountValue / 100);
    } else {
      return discountValue;
    }
  }

  double get taxAmount {
    final taxableAmount = subtotal - discountAmount;
    return taxableAmount * taxRate;
  }

  double get total {
    final base = subtotal - discountAmount;
    return base + taxAmount;
  }

  double get changeReturned {
    if (paymentMethod == PaymentMethod.cash && amountPaid > total) {
      return amountPaid - total;
    }
    return 0.0;
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        items,
        discountType,
        discountValue,
        taxRate,
        paymentMethod,
        amountPaid,
        dateTime,
        status,
        customerName,
      ];

  Order copyWith({
    String? id,
    String? orderNumber,
    List<CartItem>? items,
    DiscountType? discountType,
    double? discountValue,
    double? taxRate,
    PaymentMethod? paymentMethod,
    double? amountPaid,
    DateTime? dateTime,
    OrderStatus? status,
    String? customerName,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxRate: taxRate ?? this.taxRate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'items': items.map((e) => e.toJson()).toList(),
        'discountType': discountType.index,
        'discountValue': discountValue,
        'taxRate': taxRate,
        'paymentMethod': paymentMethod?.index,
        'amountPaid': amountPaid,
        'dateTime': dateTime.toIso8601String(),
        'status': status.index,
        'customerName': customerName,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        discountType: DiscountType.values[json['discountType'] as int? ?? 0],
        discountValue: (json['discountValue'] as num).toDouble(),
        taxRate: (json['taxRate'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] != null
            ? PaymentMethod.values[json['paymentMethod'] as int]
            : null,
        amountPaid: (json['amountPaid'] as num).toDouble(),
        dateTime: DateTime.parse(json['dateTime'] as String),
        status: OrderStatus.values[json['status'] as int? ?? 0],
        customerName: json['customerName'] as String? ?? '',
      );
}
