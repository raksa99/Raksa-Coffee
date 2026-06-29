import 'package:equatable/equatable.dart';
import '../../../menu/domain/models/product.dart';
import '../../../menu/domain/models/modifier.dart';

class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  // Maps ModifierGroup ID/Name -> Selected Options
  final Map<String, List<ModifierOption>> selectedModifiers;
  final String notes;

  const CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedModifiers = const {},
    this.notes = '',
  });

  // Calculate base price plus selected modifier prices
  double get unitPrice {
    double price = product.basePrice;
    for (var options in selectedModifiers.values) {
      for (var option in options) {
        price += option.price;
      }
    }
    return price;
  }

  double get totalPrice => unitPrice * quantity;

  @override
  List<Object?> get props => [id, product, quantity, selectedModifiers, notes];

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    Map<String, List<ModifierOption>>? selectedModifiers,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product.toJson(),
        'quantity': quantity,
        'selectedModifiers': selectedModifiers.map(
          (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
        ),
        'notes': notes,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawModifiers = json['selectedModifiers'];
    Map<String, List<ModifierOption>> parsedModifiers = {};
    if (rawModifiers is Map) {
      rawModifiers.forEach((key, value) {
        if (value is List) {
          parsedModifiers[key.toString()] = value
              .map((e) => ModifierOption.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      });
    }

    return CartItem(
      id: json['id'] as String? ?? '',
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
      quantity: json['quantity'] as int? ?? 1,
      selectedModifiers: parsedModifiers,
      notes: json['notes'] as String? ?? '',
    );
  }
}
