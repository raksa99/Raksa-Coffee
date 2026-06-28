import 'package:equatable/equatable.dart';
import '../../domain/models/product.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<Product> allProducts;
  final List<String> categories;
  final String selectedCategory;

  const MenuLoaded({
    required this.allProducts,
    required this.categories,
    required this.selectedCategory,
  });

  List<Product> get filteredProducts {
    if (selectedCategory == 'All' || selectedCategory.isEmpty) {
      return allProducts;
    }
    return allProducts.where((e) => e.category == selectedCategory).toList();
  }

  @override
  List<Object?> get props => [allProducts, categories, selectedCategory];
}

class MenuError extends MenuState {
  final String message;

  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}
