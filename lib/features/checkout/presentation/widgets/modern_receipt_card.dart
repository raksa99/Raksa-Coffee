import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order.dart';

class ModernReceiptCard extends StatelessWidget {
  final Order order;

  const ModernReceiptCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Background and border colors matching modern cards
    final cardBg = isDark ? const Color(0xFF1E1A18) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3);
    final mutedText = isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TOP HEADER BRANDING
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                color: theme.colorScheme.primary.withAlpha(20),
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_cafe,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'RAKSA COFFEE',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sangkat Phnom Penh Thmey, Khan Sen Sok',
                      style: TextStyle(fontSize: 12, color: mutedText),
                    ),
                    Text(
                      'Phnom Penh',
                      style: TextStyle(fontSize: 12, color: mutedText),
                    ),
                    Text(
                      'Tel: +855 96 798 2573',
                      style: TextStyle(fontSize: 12, color: mutedText),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ORDER DETAILS LEDGER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order ID: #${order.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Date: ${order.dateTime.month}/${order.dateTime.day}/${order.dateTime.year}',
                          style: TextStyle(fontSize: 12, color: mutedText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer: ${order.customerName}',
                          style: TextStyle(fontSize: 13, color: mutedText),
                        ),
                        Text(
                          'Time: ${order.dateTime.hour.toString().padLeft(2, '0')}:${order.dateTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: mutedText),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const _DashedDivider(),
                    const SizedBox(height: 16),

                    // LIST OF ITEMS
                    Text(
                      'itemsPurchased'.tr(context).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        
                        // Compile modifiers subtitle
                        final List<String> modNames = [];
                        for (var options in item.selectedModifiers.values) {
                          modNames.addAll(options.map((e) => e.name));
                        }
                        final modifiersText = modNames.join(', ');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.quantity}x',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (modifiersText.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            modifiersText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                        if (item.notes.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Note: ${item.notes}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.formatUsd(item.totalPrice),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    const _DashedDivider(),
                    const SizedBox(height: 16),

                    _buildRow('subtotal'.tr(context), CurrencyFormatter.formatUsd(order.subtotal), isBold: false, theme: theme),
                    if (order.discountAmount > 0)
                      _buildRow(
                        'discount'.tr(context), 
                        '-${CurrencyFormatter.formatUsd(order.discountAmount)}', 
                        isBold: false, 
                        theme: theme,
                        valueColor: theme.colorScheme.primary,
                      ),
                    _buildRow('tax'.tr(context), CurrencyFormatter.formatUsd(order.taxAmount), isBold: false, theme: theme),
                    
                    const SizedBox(height: 12),
                    
                    // Grand total highlighted block
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${'total'.tr(context)} (USD)",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatUsd(order.total),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${'total'.tr(context)} (KHR)",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatKhr(order.total),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const _DashedDivider(),
                    const SizedBox(height: 16),

                    // PAYMENT DETAILS TICKET
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${'paymentMethod'.tr(context)}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${'paidVia'.tr(context)} ${order.paymentMethod == PaymentMethod.cash ? 'cash'.tr(context).toUpperCase() : order.paymentMethod == PaymentMethod.card ? 'card'.tr(context).toUpperCase() : 'qrScan'.tr(context).toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    if (order.paymentMethod == PaymentMethod.cash) ...[
                      const SizedBox(height: 8),
                      _buildRow('${'amountTendered'.tr(context)} (USD)', CurrencyFormatter.formatUsd(order.amountPaid), isBold: false, theme: theme),
                      _buildRow('${'changeDue'.tr(context)} (USD)', CurrencyFormatter.formatUsd(order.changeReturned), isBold: false, theme: theme),
                      _buildRow('${'changeDue'.tr(context)} (KHR)', CurrencyFormatter.formatKhr(order.changeReturned), isBold: true, theme: theme, valueColor: theme.colorScheme.secondary),
                    ],

                    const SizedBox(height: 24),
                    
                    // E-Invoice QR Code
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: QrImageView(
                              data: _buildInvoiceQrData(),
                              version: QrVersions.auto,
                              size: 120,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF1B1411),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1B1411),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'scanViewEInvoice'.tr(context),
                            style: TextStyle(fontSize: 11, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInvoiceQrData() {
    final invoice = {
      'shop': 'Raksa Coffee',
      'address': 'Sangkat Phnom Penh Thmey, Khan Sen Sok, Phnom Penh',
      'tel': '+855 96 798 2573',
      'invoice': '#${order.orderNumber}',
      'date': '${order.dateTime.year}-${order.dateTime.month.toString().padLeft(2, '0')}-${order.dateTime.day.toString().padLeft(2, '0')}',
      'time': '${order.dateTime.hour.toString().padLeft(2, '0')}:${order.dateTime.minute.toString().padLeft(2, '0')}',
      'customer': order.customerName.isNotEmpty ? order.customerName : 'Walk-in',
      'items': order.items.map((item) => {
        'name': item.product.name,
        'qty': item.quantity,
        'price': '\$${item.totalPrice.toStringAsFixed(2)}',
      }).toList(),
      'subtotal': '\$${order.subtotal.toStringAsFixed(2)}',
      'discount': '\$${order.discountAmount.toStringAsFixed(2)}',
      'tax': '\$${order.taxAmount.toStringAsFixed(2)}',
      'total_usd': '\$${order.total.toStringAsFixed(2)}',
      'total_khr': '${(order.total * 4100).toStringAsFixed(0)}៛',
      'payment': order.paymentMethod == PaymentMethod.cash
          ? 'Cash'
          : order.paymentMethod == PaymentMethod.card
              ? 'Card'
              : 'QR/Bakong',
    };
    final jsonStr = jsonEncode(invoice);
    final base64Data = base64Url.encode(utf8.encode(jsonStr));
    // Dynamically build the URL including the base path (e.g., /Raksa-Coffee/)
    String basePath = Uri.base.path;
    if (!basePath.endsWith('/')) {
      basePath = '$basePath/';
    }
    return '${Uri.base.origin}${basePath}invoice.html?data=$base64Data';
  }

  Widget _buildRow(String label, String value, {required bool isBold, required ThemeData theme, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey[400],
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
