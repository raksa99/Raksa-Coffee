import 'package:equatable/equatable.dart';

class ModifierOption extends Equatable {
  final String id;
  final String name;
  final double price;

  const ModifierOption({
    required this.id,
    required this.name,
    this.price = 0.0,
  });

  @override
  List<Object?> get props => [id, name, price];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };

  factory ModifierOption.fromJson(Map<String, dynamic> json) => ModifierOption(
    id: json['id'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
  );
}

class ModifierGroup extends Equatable {
  final String id;
  final String name;
  final bool isRequired;
  final bool allowMultiple;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.allowMultiple = false,
    required this.options,
  });

  @override
  List<Object?> get props => [id, name, isRequired, allowMultiple, options];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isRequired': isRequired,
    'allowMultiple': allowMultiple,
    'options': options.map((e) => e.toJson()).toList(),
  };

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    isRequired: json['isRequired'] as bool? ?? false,
    allowMultiple: json['allowMultiple'] as bool? ?? false,
    options: (json['options'] as List<dynamic>)
        .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
