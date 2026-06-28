import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/domain/models/cart_item.dart';
import '../../domain/models/modifier.dart';
import '../../domain/models/product.dart';

class ModifierModal extends StatefulWidget {
  final Product product;
  final Function(CartItem) onAddToCart;

  const ModifierModal({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ModifierModal> createState() => _ModifierModalState();
}

class _ModifierModalState extends State<ModifierModal> {
  final Map<String, List<ModifierOption>> _selections = {};
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initializeDefaults() {
    for (var group in widget.product.modifierGroups) {
      if (group.isRequired && group.options.isNotEmpty) {
        // Automatically pre-select first option for required groups
        _selections[group.id] = [group.options.first];
      } else {
        _selections[group.id] = [];
      }
    }
  }

  void _toggleOption(ModifierGroup group, ModifierOption option) {
    setState(() {
      final currentList = _selections[group.id] ?? [];
      if (group.allowMultiple) {
        if (currentList.any((e) => e.id == option.id)) {
          _selections[group.id] = currentList.where((e) => e.id != option.id).toList();
        } else {
          _selections[group.id] = [...currentList, option];
        }
      } else {
        // Single selection
        _selections[group.id] = [option];
      }
    });
  }

  double get _currentUnitPrice {
    double price = widget.product.basePrice;
    for (var options in _selections.values) {
      for (var option in options) {
        price += option.price;
      }
    }
    return price;
  }

  double get _currentTotalPrice => _currentUnitPrice * _quantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: theme.textTheme.headlineMedium,
                        ),
                        if (widget.product.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.product.description,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      CurrencyFormatter.format(widget.product.basePrice),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Modifier Options List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: widget.product.modifierGroups.length + 1,
                itemBuilder: (context, index) {
                  if (index == widget.product.modifierGroups.length) {
                    // Special item for order notes
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special Instructions',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Extra hot, splash of cinnamon...',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                              ),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    );
                  }

                  final group = widget.product.modifierGroups[index];
                  final currentSelections = _selections[group.id] ?? [];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            if (group.isRequired) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withAlpha(26),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'REQUIRED',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: group.options.map((option) {
                            final isSelected = currentSelections.any((e) => e.id == option.id);
                            return InkWell(
                              onTap: () => _toggleOption(group, option),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isDark ? const Color(0xFF1E1A18) : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : (isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3)),
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withAlpha(50),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      option.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? const Color(0xFFF7F3EE) : const Color(0xFF2C1B14)),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (option.price > 0) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '+${CurrencyFormatter.format(option.price)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isSelected
                                              ? Colors.white70
                                              : theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const Divider(height: 1),
            
            // Bottom Action Bar (Quantity + Add Button)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Quantity adjusters
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF3EFE9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF38312E) : const Color(0xFFEADFD3),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove, size: 20),
                          color: theme.colorScheme.primary,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_quantity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add, size: 20),
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Submit Add-to-Cart
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate required modifier groups
                        for (var group in widget.product.modifierGroups) {
                          if (group.isRequired && (_selections[group.id]?.isEmpty ?? true)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select an option for ${group.name}'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                            return;
                          }
                        }

                        // Create CartItem
                        final cartItem = CartItem(
                          id: const Uuid().v4(),
                          product: widget.product,
                          quantity: _quantity,
                          selectedModifiers: Map.from(_selections),
                          notes: _notesController.text,
                        );
                        
                        widget.onAddToCart(cartItem);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Add to Cart • ${CurrencyFormatter.format(_currentTotalPrice)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
