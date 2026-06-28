import 'package:equatable/equatable.dart';
import 'modifier.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final List<ModifierGroup> modifierGroups;

  const Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.basePrice,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.modifierGroups = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        basePrice,
        category,
        imageUrl,
        isAvailable,
        modifierGroups,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'basePrice': basePrice,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
        'modifierGroups': modifierGroups.map((e) => e.toJson()).toList(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        basePrice: (json['basePrice'] as num).toDouble(),
        category: json['category'] as String,
        imageUrl: json['imageUrl'] as String?,
        isAvailable: json['isAvailable'] as bool? ?? true,
        modifierGroups: (json['modifierGroups'] as List<dynamic>?)
                ?.map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? basePrice,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    List<ModifierGroup>? modifierGroups,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      modifierGroups: modifierGroups ?? this.modifierGroups,
    );
  }
}
