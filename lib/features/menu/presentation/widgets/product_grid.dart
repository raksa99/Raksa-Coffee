import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../cart/domain/models/cart_item.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../bloc/menu_bloc.dart';
import '../bloc/menu_event.dart';
import '../bloc/menu_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'modifier_modal.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        if (state is MenuLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is MenuError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load products: ${state.message}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<MenuBloc>().add(LoadMenu());
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (state is MenuLoaded) {
          final products = state.filteredProducts;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Categories horizontal list
              SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    final isSelected = category == state.selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(category.toLowerCase().replaceAll('-', '').tr(context)),
                        labelStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFF7F3EE) : const Color(0xFF2C1B14)),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: isDark ? const Color(0xFF1E1A18) : Colors.white,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3)),
                          ),
                        ),
                        onSelected: (_) {
                          context.read<MenuBloc>().add(SelectCategory(category));
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Grid list of products
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'No products found in this category.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Dynamic cross axis count based on container width
                          int crossAxisCount = 2;
                          if (constraints.maxWidth > 800) {
                            crossAxisCount = 4;
                          } else if (constraints.maxWidth > 550) {
                            crossAxisCount = 3;
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.70,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];

                              return ProductCard(
                                product: product,
                                onTap: () {
                                  if (product.modifierGroups.isNotEmpty) {
                                    // Open modal for customization
                                    showDialog(
                                      context: context,
                                      builder: (_) {
                                        return ModifierModal(
                                          product: product,
                                          onAddToCart: (cartItem) {
                                            context.read<CartBloc>().add(AddToCart(cartItem));
                                          },
                                        );
                                      },
                                    );
                                  } else {
                                    // Direct add to cart
                                    final cartItem = CartItem(
                                      id: const Uuid().v4(),
                                      product: product,
                                      quantity: 1,
                                      selectedModifiers: const {},
                                      notes: '',
                                    );
                                    context.read<CartBloc>().add(AddToCart(cartItem));
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${product.name} added to cart'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: theme.colorScheme.primary,
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
