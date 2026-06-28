import '../../features/checkout/domain/models/order.dart';
import 'currency_formatter.dart';

class ReceiptFormatter {
  static String format(Order order, {int width = 40}) {
    final buffer = StringBuffer();

    // Helper: Center text
    String center(String text) {
      if (text.length >= width) return text.substring(0, width);
      final padding = (width - text.length) ~/ 2;
      return ' ' * padding + text;
    }

    // Helper: Left and right justify
    String leftRight(String left, String right) {
      final spaceCount = width - left.length - right.length;
      if (spaceCount <= 0) {
        return '$left $right'; // Fallback spacing
      }
      return left + ' ' * spaceCount + right;
    }

    // Header Shop Info
    buffer.writeln(center('RAKSA COFFEE'));
    buffer.writeln(center('123 Espresso Blvd, Suite 100'));
    buffer.writeln(center('Tel: (555) 019-2831'));
    buffer.writeln('=' * width);
    
    // Order Info
    buffer.writeln(leftRight('Order ID: ${order.orderNumber}', 'Date: ${order.dateTime.month}/${order.dateTime.day}/${order.dateTime.year}'));
    buffer.writeln(leftRight('Customer: ${order.customerName}', 'Time: ${order.dateTime.hour.toString().padLeft(2, '0')}:${order.dateTime.minute.toString().padLeft(2, '0')}'));
    buffer.writeln('-' * width);

    // Cart Line Items
    for (var item in order.items) {
      final nameStr = '${item.quantity}x ${item.product.name}';
      final totalStr = CurrencyFormatter.formatUsd(item.totalPrice);
      buffer.writeln(leftRight(nameStr, totalStr));
      
      // Modifiers
      for (var groupEntry in item.selectedModifiers.entries) {
        for (var option in groupEntry.value) {
          final modStr = '  + ${option.name}';
          final modPriceStr = option.price > 0 
              ? '(+${CurrencyFormatter.formatUsd(option.price)})' 
              : '';
          buffer.writeln(leftRight(modStr, modPriceStr));
        }
      }
      if (item.notes.isNotEmpty) {
        buffer.writeln('  Note: ${item.notes}');
      }
    }
    buffer.writeln('-' * width);

    // Pricing Totals (Dual Currency)
    buffer.writeln(leftRight('Subtotal (USD):', CurrencyFormatter.formatUsd(order.subtotal)));
    buffer.writeln(leftRight('Subtotal (KHR):', CurrencyFormatter.formatKhr(order.subtotal)));
    
    if (order.discountValue > 0) {
      final discLabel = order.discountType == DiscountType.percentage
          ? 'Discount (${order.discountValue.toStringAsFixed(0)}%):'
          : 'Discount:';
      buffer.writeln(leftRight('$discLabel (USD)', '-${CurrencyFormatter.formatUsd(order.discountAmount)}'));
      buffer.writeln(leftRight('$discLabel (KHR)', '-${CurrencyFormatter.formatKhr(order.discountAmount)}'));
    }
    
    buffer.writeln(leftRight('Tax (${(order.taxRate * 100).toStringAsFixed(0)}%) (USD):', CurrencyFormatter.formatUsd(order.taxAmount)));
    buffer.writeln(leftRight('Tax (${(order.taxRate * 100).toStringAsFixed(0)}%) (KHR):', CurrencyFormatter.formatKhr(order.taxAmount)));
    buffer.writeln('=' * width);
    buffer.writeln(leftRight('TOTAL (USD):', CurrencyFormatter.formatUsd(order.total)));
    buffer.writeln(leftRight('TOTAL (KHR):', CurrencyFormatter.formatKhr(order.total)));
    buffer.writeln('=' * width);

    // Payment Information
    final paymentStr = order.paymentMethod?.name.toUpperCase() ?? 'PENDING';
    buffer.writeln(leftRight('Payment Method:', paymentStr));
    if (order.paymentMethod == PaymentMethod.cash) {
      buffer.writeln(leftRight('Amount Tendered (USD):', CurrencyFormatter.formatUsd(order.amountPaid)));
      buffer.writeln(leftRight('Change (USD):', CurrencyFormatter.formatUsd(order.changeReturned)));
      buffer.writeln(leftRight('Change (KHR):', CurrencyFormatter.formatKhr(order.changeReturned)));
    }
    buffer.writeln('-' * width);

    // Bottom Footer
    buffer.writeln(center('Thank you for your visit!'));
    buffer.writeln(center('Share your experience:'));
    buffer.writeln(center('www.coffeehouse.com/review'));
    
    return buffer.toString();
  }
}
