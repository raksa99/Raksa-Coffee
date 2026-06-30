import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../cart/domain/models/cart_item.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../domain/models/product.dart';
import '../bloc/menu_bloc.dart';
import '../bloc/menu_event.dart';
import '../bloc/menu_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'modifier_modal.dart';
import 'product_card.dart';
import '../../../../core/utils/animations.dart';

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
                            key: ValueKey<String>('${state.selectedCategory}_${products.length}'),
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

                              return StaggeredEntranceAnimation(
                                index: index,
                                child: ProductCard(
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
                                  onDelete: () {
                                    _showDeleteConfirmation(context, product);
                                  },
                                ),
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

  void _showDeleteConfirmation(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: isDark ? const Color(0xFF1C1816) : Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular warning icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'deleteMenuItem'.tr(context),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2C1B14),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'confirmDelete'.tr(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Product Preview Card (Visual confirmation)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF26211F) : const Color(0xFFF8F5F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 48,
                                height: 48,
                                color: isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3),
                                child: const Icon(Icons.image, size: 20),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_cafe_outlined, size: 20),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.category,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3),
                            ),
                          ),
                          child: Text(
                            'cancel'.tr(context),
                            style: TextStyle(
                              color: isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<MenuBloc>().add(DeleteProduct(product.id));
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text('delete'.tr(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
