import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/local_database.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../checkout/domain/models/order.dart';
import '../../../checkout/presentation/bloc/checkout_bloc.dart';
import '../../../checkout/presentation/widgets/checkout_dialog.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'queue_list_dialog.dart';
import 'animated_cart_list.dart';
import '../../../../core/utils/animations.dart';

class CartSidebar extends StatefulWidget {
  const CartSidebar({super.key});

  @override
  State<CartSidebar> createState() => _CartSidebarState();
}

class _CartSidebarState extends State<CartSidebar> {
  final TextEditingController _customerNameController = TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  void _showHoldOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('holdOrderTitle'.tr(context)),
          content: TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: 'enterHoldName'.tr(context),
              hintText: 'holdNamePlaceholder'.tr(context),
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _customerNameController.clear();
                Navigator.pop(dialogContext);
              },
              child: Text('cancel'.tr(context)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _customerNameController.text;
                context.read<CartBloc>().add(HoldOrder(customerName: name));
                _customerNameController.clear();
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order saved to queue successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('hold'.tr(context)),
            ),
          ],
        );
      },
    );
  }

  void _showDiscountDialog(BuildContext context, CartState state) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        DiscountType selectedType = state.discountType;
        double selectedValue = state.discountValue;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('customDiscount'.tr(context)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('% Percentage')),
                          selected: selectedType == DiscountType.percentage,
                          onSelected: (_) => setState(() {
                            selectedType = DiscountType.percentage;
                            selectedValue = 0.0;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('\$ Flat Rate')),
                          selected: selectedType == DiscountType.fixed,
                          onSelected: (_) => setState(() {
                            selectedType = DiscountType.fixed;
                            selectedValue = 0.0;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Presets
                  if (selectedType == DiscountType.percentage) ...[
                    Wrap(
                      spacing: 8,
                      children: [5.0, 10.0, 15.0, 20.0].map((val) {
                        return ChoiceChip(
                          label: Text('${val.toStringAsFixed(0)}%'),
                          selected: selectedValue == val,
                          onSelected: (_) => setState(() => selectedValue = val),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      children: [1.0, 2.0, 5.0, 10.0].map((val) {
                        return ChoiceChip(
                          label: Text('\$${val.toStringAsFixed(0)}'),
                          selected: selectedValue == val,
                          onSelected: (_) => setState(() => selectedValue = val),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Custom field
                  TextFormField(
                    initialValue: selectedValue > 0 ? selectedValue.toStringAsFixed(2) : '',
                    decoration: InputDecoration(
                      labelText: selectedType == DiscountType.percentage ? 'Discount (%)' : 'Discount (\$)',
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      selectedValue = double.tryParse(val) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Reset Button
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedValue = 0.0;
                      });
                    },
                    child: const Text('Clear Discount'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('cancel'.tr(context)),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<CartBloc>().add(ApplyDiscount(selectedType, selectedValue));
                    Navigator.pop(dialogContext);
                  },
                  child: Text('apply'.tr(context)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final isMobile = MediaQuery.of(context).size.width < 750;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151211) : Colors.white,
            borderRadius: isMobile
                ? BorderRadius.zero
                : const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
            border: isMobile
                ? null
                : Border(
                    left: BorderSide(
                      color: isDark ? const Color(0xFF2A2321) : const Color(0xFFE8DFD5),
                      width: 1.2,
                    ),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Queue & Cart Title Panel
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'currentOrder'.tr(context),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Queue Button with count badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            context.read<CartBloc>().add(LoadQueuedOrdersList());
                            showDialog(
                              context: context,
                              builder: (_) {
                                return QueueListDialog(
                                  queuedOrders: state.queuedOrders,
                                  cartBloc: context.read<CartBloc>(),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.pause_circle_outline),
                          tooltip: 'heldQueue'.tr(context),
                        ),
                        if (state.queuedOrders.isNotEmpty)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${state.queuedOrders.length}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Active cart lines
              Expanded(
                child: state.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_basket_outlined,
                              size: 64,
                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'emptyCart'.tr(context),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : AnimatedCartList(
                        items: state.items,
                        onQuantityChanged: (item, q) {
                          context.read<CartBloc>().add(UpdateCartItemQuantity(item.id, q));
                        },
                        onRemove: (item) {
                          context.read<CartBloc>().add(RemoveFromCart(item.id));
                        },
                      ),
              ),

              const Divider(height: 1),

              // Billing and actions block
              Container(
                color: isDark ? const Color(0xFF151211) : const Color(0xFFFAF8F5),
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D1918) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A2321) : const Color(0xFFE8DFD5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 30 : 10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRow(
                        'Subtotal', 
                        CurrencyFormatter.formatUsd(state.subtotal),
                        theme,
                      ),
                      
                      // Clickable discount row
                      InkWell(
                        onTap: state.items.isEmpty ? null : () => _showDiscountDialog(context, state),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        state.discountValue > 0
                                            ? 'Discount (${state.discountType == DiscountType.percentage ? '${state.discountValue.toStringAsFixed(0)}%' : 'Fixed'})'
                                            : 'Add Discount',
                                        style: TextStyle(
                                          color: state.discountValue > 0 
                                              ? theme.colorScheme.primary 
                                              : theme.colorScheme.secondary,
                                          fontWeight: state.discountValue > 0 ? FontWeight.bold : FontWeight.normal,
                                          fontFamily: 'Outfit',
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit_outlined, 
                                      size: 14, 
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                state.discountValue > 0
                                    ? '-${CurrencyFormatter.formatUsd(state.discountAmount)}'
                                    : '\$0.00',
                                style: TextStyle(
                                  color: state.discountValue > 0 ? theme.colorScheme.primary : null,
                                  fontWeight: state.discountValue > 0 ? FontWeight.bold : FontWeight.normal,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      _buildRow(
                        'Tax (8%)', 
                        CurrencyFormatter.formatUsd(state.taxAmount),
                        theme,
                      ),
                      
                      const SizedBox(height: 8),
                      Container(
                        height: 1.0,
                        color: isDark ? const Color(0xFF2A2321) : const Color(0xFFE8DFD5),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildRow(
                        'Total (USD)', 
                        CurrencyFormatter.formatUsd(state.total),
                        theme,
                        isBold: true,
                        fontSize: 15,
                      ),
                      _buildRow(
                        'Total (KHR)', 
                        CurrencyFormatter.formatKhr(state.total),
                        theme,
                        isBold: true,
                        fontSize: 15,
                      ),
                      
                      const SizedBox(height: 16),

                      // Actions buttons
                      Row(
                        children: [
                          // HOLD button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.items.isEmpty
                                  ? null
                                  : () => _showHoldOrderDialog(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('holdOrder'.tr(context)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // PAY button with Premium Gradient
                          Expanded(
                            child: AnimatedOpacity(
                              opacity: state.items.isEmpty ? 0.6 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: ScaleBouncePressReaction(
                                scaleFactor: state.items.isEmpty ? 1.0 : 0.95,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: state.items.isEmpty
                                        ? null
                                        : LinearGradient(
                                            colors: [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.primary.withAlpha(200),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: state.items.isEmpty
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: theme.colorScheme.primary.withAlpha(60),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: state.items.isEmpty
                                        ? null
                                        : () {
                                            final orderId = const Uuid().v4();
                                            final dailyOrdersCount = LocalDatabase.getSalesHistory().length + LocalDatabase.getQueuedOrders().length + 1;
                                            final orderNumber = dailyOrdersCount.toString().padLeft(4, '0');

                                            // Generate Order invoice model
                                            final currentOrder = Order(
                                              id: orderId,
                                              orderNumber: orderNumber,
                                              items: state.items,
                                              discountType: state.discountType,
                                              discountValue: state.discountValue,
                                              taxRate: state.taxRate,
                                              dateTime: DateTime.now(),
                                              status: OrderStatus.queued,
                                            );

                                            // Open checkout modal
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) {
                                                return BlocProvider.value(
                                                  value: context.read<CheckoutBloc>(),
                                                  child: BlocProvider.value(
                                                    value: context.read<CartBloc>(),
                                                    child: CheckoutDialog(order: currentOrder),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    child: Text('checkout'.tr(context)),
                                  ),
                                ),
                              ),
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
        );
      },
    );
  }

  Widget _buildRow(String label, String value, ThemeData theme, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: fontSize,
              color: isBold ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
