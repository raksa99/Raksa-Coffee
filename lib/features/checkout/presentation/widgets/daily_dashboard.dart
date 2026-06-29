import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/receipt_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';

class DailyDashboard extends StatelessWidget {
  const DailyDashboard({super.key});

  void _showReprintReceiptDialog(BuildContext context, Order order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receiptText = ReceiptFormatter.format(order);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${order.orderNumber} Receipt'),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: Container(
            width: 400,
            height: 480,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF3EFE9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                receiptText,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Re-printing receipt...')),
                  );
                }
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Re-print'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetDialog(BuildContext context) {
    final isKhmer = AppLocalizations.of(context)?.locale.languageCode == 'km';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isKhmer ? 'សម្អាតទិន្នន័យលក់?' : 'Reset Daily Sales?'),
          content: Text(
            isKhmer
                ? 'សកម្មភាពនេះនឹងលុបប្រវត្តិប្រតិបត្តិការទាំងអស់ជាអចិន្ត្រៃយ៍ពីម៉ាស៊ីន។ សូមប្រាកដថាអ្នកបានបោះពុម្ពរបាយការណ៍ប្រចាំថ្ងៃរួចរាល់។'
                : 'This action will clear all transaction history permanently from local database. Make sure you have printed daily reports.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isKhmer ? 'បោះបង់' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CheckoutBloc>().add(ClearSalesHistory());
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isKhmer ? 'បានសម្អាតដោយជោគជ័យ' : 'Database reset successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: Text(isKhmer ? 'យល់ព្រម' : 'Reset All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 750;

    // Load sales history on build
    context.read<CheckoutBloc>().add(LoadSalesHistory());

    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        if (state is CheckoutInitial || state is CheckoutProcessing) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Order> sales = [];
        if (state is SalesHistoryLoaded) {
          sales = state.sales;
        } else if (state is CheckoutSuccess) {
          context.read<CheckoutBloc>().add(LoadSalesHistory());
          return const Center(child: CircularProgressIndicator());
        }

        // Calculate KPIs
        double totalSales = 0.0;
        int totalOrders = sales.length;
        Map<String, int> itemQuantities = {};

        for (var order in sales) {
          totalSales += order.total;
          for (var item in order.items) {
            final name = item.product.name;
            itemQuantities[name] = (itemQuantities[name] ?? 0) + item.quantity;
          }
        }

        // Get Top Selling Items
        final sortedItems = itemQuantities.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topItems = sortedItems.take(3).toList();

        final avgTicket = totalOrders > 0 ? totalSales / totalOrders : 0.0;

        // Content header (Title + Reset button)
        final headerRow = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'salesReport'.tr(context),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF2C1B14),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmResetDialog(context),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text('resetHistory'.tr(context)),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withAlpha(76)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        );

        // KPI grid widget
        final kpiGrid = GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 1.55 : 1.5,
          children: [
            _buildKpiCard(
              title: 'grossSales'.tr(context).toUpperCase(),
              value: CurrencyFormatter.format(totalSales),
              icon: Icons.payments_outlined,
              color: theme.colorScheme.primary,
              context: context,
            ),
            _buildKpiCard(
              title: 'ordersCount'.tr(context).toUpperCase(),
              value: '$totalOrders',
              icon: Icons.receipt_long_outlined,
              color: theme.colorScheme.secondary,
              context: context,
            ),
            _buildKpiCard(
              title: 'avgTicket'.tr(context).toUpperCase(),
              value: CurrencyFormatter.format(avgTicket),
              icon: Icons.analytics_outlined,
              color: const Color(0xFF4A7C59),
              context: context,
            ),
            _buildKpiCard(
              title: 'ITEMS DISPENSED',
              value: '${itemQuantities.values.fold(0, (sum, val) => sum + val)}',
              icon: Icons.coffee_outlined,
              color: const Color(0xFF537A9B),
              context: context,
            ),
          ],
        );

        // Top Selling list
        final topSellingCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_outlined, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      'topSelling'.tr(context),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (topItems.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No items sold yet today.'),
                    ),
                  )
                else
                  ...topItems.map((entry) {
                    final rank = topItems.indexOf(entry) + 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: rank == 1
                                  ? theme.colorScheme.secondary
                                  : (isDark ? const Color(0xFF26211F) : const Color(0xFFF3EFE9)),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: rank == 1 ? Colors.white : theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${entry.value} sold',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );

        // Ledger list builder
        Widget buildLedgerList({required bool shrinkWrap, required ScrollPhysics physics}) {
          return ListView.builder(
            itemCount: sales.length,
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemBuilder: (context, index) {
              final order = sales[sales.length - 1 - index];
              final timeStr = '${order.dateTime.hour.toString().padLeft(2, '0')}:${order.dateTime.minute.toString().padLeft(2, '0')}';
              final itemCount = order.items.fold(0, (sum, i) => sum + i.quantity);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131110) : const Color(0xFFFAF6F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                  ),
                ),
                child: InkWell(
                  onTap: () => _showReprintReceiptDialog(context, order),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.orderNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$timeStr • $itemCount items • ${order.paymentMethod?.name.toUpperCase()}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          CurrencyFormatter.format(order.total),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        // Ledger Card
        final ledgerCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'salesLedger'.tr(context),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (sales.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No sales recorded today.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? const Color(0xFF6E625D) : const Color(0xFFA79C95),
                        ),
                      ),
                    ),
                  )
                else
                  isMobile
                      ? buildLedgerList(shrinkWrap: true, physics: const NeverScrollableScrollPhysics())
                      : Expanded(
                          child: buildLedgerList(shrinkWrap: false, physics: const AlwaysScrollableScrollPhysics()),
                        ),
              ],
            ),
          ),
        );

        // Build main screen responsive layout
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerRow,
              const SizedBox(height: 16),
              Expanded(
                child: isMobile
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            kpiGrid,
                            const SizedBox(height: 16),
                            topSellingCard,
                            const SizedBox(height: 16),
                            ledgerCard,
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  kpiGrid,
                                  const SizedBox(height: 16),
                                  topSellingCard,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: ledgerCard,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A18) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
