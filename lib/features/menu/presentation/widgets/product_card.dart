import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/product.dart';

import '../../../../core/utils/animations.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  Widget _buildPlaceholderImage(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF26211F) : const Color(0xFFF3EFE9),
      child: Icon(
        product.category == 'Pastries' ? Icons.cookie_outlined : Icons.local_cafe_outlined,
        size: 36,
        color: theme.colorScheme.secondary.withAlpha(100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleBouncePressReaction(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: product.isAvailable ? onTap : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image Header
                Expanded(
                  flex: 5,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(theme, isDark),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: isDark ? const Color(0xFF26211F) : const Color(0xFFF3EFE9),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                        )
                      : _buildPlaceholderImage(theme, isDark),
                ),

                // Info Section
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.modifierGroups.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 12,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'CUSTOMISABLE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ] else ...[
                          const SizedBox(height: 16),
                        ],
                        
                        // Product Name
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        
                        // Description
                        Expanded(
                          child: Text(
                            product.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? const Color(0xFFA3958F) : const Color(0xFF6E5E57),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Price & Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              CurrencyFormatter.formatUsd(product.basePrice),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withAlpha(200),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withAlpha(60),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Floating category tag
            Positioned(
              top: 8,
              left: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withAlpha(160),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isDark ? Colors.white : Colors.black).withAlpha(30),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      product.category.toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.5,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Out of stock overlay
            if (!product.isAvailable)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                    child: Container(
                      color: Colors.black.withAlpha(90),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withAlpha(220),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha(50),
                            width: 1.0,
                          ),
                        ),
                        child: const Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Delete button overlay in top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withAlpha(128),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  onPressed: onDelete,
                  tooltip: 'Delete Product',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
