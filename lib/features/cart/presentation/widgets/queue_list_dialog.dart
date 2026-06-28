import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../checkout/domain/models/order.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

class QueueListDialog extends StatelessWidget {
  final List<Order> queuedOrders;
  final CartBloc cartBloc;

  const QueueListDialog({
    super.key,
    required this.queuedOrders,
    required this.cartBloc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Held Orders Queue',
                    style: theme.textTheme.headlineMedium,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: queuedOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pause_circle_outline,
                              size: 64,
                              color: isDark ? Colors.grey[700] : Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No held orders found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: queuedOrders.length,
                        itemBuilder: (context, index) {
                          final order = queuedOrders[index];
                          final timeStr = '${order.dateTime.hour.toString().padLeft(2, '0')}:${order.dateTime.minute.toString().padLeft(2, '0')}';
                          final itemCount = order.items.fold(0, (sum, item) => sum + item.quantity);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1A18) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Order #${order.orderNumber}',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.secondary.withAlpha(26),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              order.customerName,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.secondary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$itemCount items • Total: ${CurrencyFormatter.format(order.total)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Held at $timeStr',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        cartBloc.add(DeleteQueuedOrder(order.id));
                                        // Quick state update refresh triggers within BlocBuilder in Parent
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        cartBloc.add(ResumeOrder(order));
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Resume'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
