import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../domain/models/order.dart';
import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'modern_receipt_card.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/network/local_database.dart';

class CheckoutDialog extends StatefulWidget {
  final Order order;

  const CheckoutDialog({super.key, required this.order});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double _amountPaid = 0.0;
  String _customCashInput = '';

  // Dynamic ABA QR & API Settings
  bool _showApiSettings = false;
  bool _isLoadingQr = false;
  String? _dynamicQrString;
  String _qrError = '';
  String _teachConcatString = '';
  String _teachHash = '';

  final _merchantIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default cash amount paid is the exact total
    _amountPaid = widget.order.total;

    // Load credentials from Hive database
    _merchantIdController.text = LocalDatabase.getSetting('aba_merchant_id', '');
    _apiKeyController.text = LocalDatabase.getSetting('aba_api_key', '');
    _apiSecretController.text = LocalDatabase.getSetting('aba_api_secret', '');

    // Auto-fetch dynamic QR if credentials exist
    if (_merchantIdController.text.isNotEmpty && _apiSecretController.text.isNotEmpty) {
      // Small post-frame callback delay to ensure context is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateDynamicQrCode();
      });
    }
  }

  @override
  void dispose() {
    _merchantIdController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  Future<void> _generateDynamicQrCode() async {
    final merchantId = _merchantIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final apiSecret = _apiSecretController.text.trim();

    if (merchantId.isEmpty || apiSecret.isEmpty) {
      setState(() {
        _dynamicQrString = null;
        _qrError = '';
      });
      return;
    }

    setState(() {
      _isLoadingQr = true;
      _qrError = '';
    });

    try {
      final reqTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      // Unique transaction ID using timestamp
      final tranId = 'pos_${widget.order.orderNumber}_${DateTime.now().millisecondsSinceEpoch % 10000}';
      final amount = widget.order.total.toStringAsFixed(2);
      const currency = 'USD';
      const paymentOption = 'abapay_khqr';

      // 1. CONCATENATION FOR THE SIGNATURE
      final rawData = '$reqTime$merchantId$tranId$amount$currency$paymentOption';
      
      // 2. HMAC-SHA512 GENERATION (base64 encoded raw bytes)
      final keyBytes = utf8.encode(apiSecret);
      final dataBytes = utf8.encode(rawData);
      final hmacSha512 = Hmac(sha512, keyBytes);
      final digest = hmacSha512.convert(dataBytes);
      final generatedHash = base64.encode(digest.bytes);

      setState(() {
        _teachConcatString = rawData;
        _teachHash = generatedHash;
      });

      // 3. SEND POST REQUEST TO ABA PAYWAY SANDBOX
      final url = Uri.parse('https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/generate-qr');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey', // Optional API key header in standard OAuth
        },
        body: jsonEncode({
          'req_time': reqTime,
          'merchant_id': merchantId,
          'tran_id': tranId,
          'amount': double.parse(amount),
          'currency': currency,
          'payment_option': paymentOption,
          'hash': generatedHash,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);
        if (resData['status'] == 0) {
          setState(() {
            _dynamicQrString = resData['qrString'] ?? resData['abapay_qr'];
            _isLoadingQr = false;
          });
        } else {
          setState(() {
            _qrError = 'ABA API Error (${resData['status']}): ${resData['description'] ?? 'Unknown'}';
            _isLoadingQr = false;
          });
        }
      } else {
        setState(() {
          _qrError = 'HTTP Error (${response.statusCode}): ${response.reasonPhrase}';
          _isLoadingQr = false;
        });
      }
    } catch (e) {
      setState(() {
        _qrError = 'Connection failed: $e';
        _isLoadingQr = false;
      });
    }
  }

  void _onQuickCashSelected(double amount) {
    setState(() {
      _amountPaid = amount;
      _customCashInput = '';
    });
  }

  void _onKeypadPressed(String val) {
    setState(() {
      if (val == 'C') {
        _customCashInput = '';
        _amountPaid = 0.0;
      } else if (val == '.') {
        if (!_customCashInput.contains('.')) {
          _customCashInput += '.';
        }
      } else {
        // Prevent typing too many decimal figures
        if (_customCashInput.contains('.') && _customCashInput.split('.')[1].length >= 2) {
          return;
        }
        _customCashInput += val;
      }

      if (_customCashInput.isNotEmpty) {
        _amountPaid = double.tryParse(_customCashInput) ?? 0.0;
      }
    });
  }

  double get _changeDue {
    if (_amountPaid > widget.order.total) {
      return _amountPaid - widget.order.total;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutSuccess) {
          // Reset active Cart
          context.read<CartBloc>().add(ClearCart());
        }
      },
      builder: (context, state) {
        // SUCCESS STATE (Show Receipt)
        if (state is CheckoutSuccess) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450, maxHeight: 680),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Success Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 36),
                        const SizedBox(width: 12),
                        Text(
                          'paymentSuccessful'.tr(context),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ModernReceiptCard(order: state.order),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Simulating print (via Bluetooth thermal printer)...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print_outlined),
                            label: Text('printReceipt'.tr(context)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('done'.tr(context)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        }

        // INITIAL & PROCESSING STATE
        final isProcessing = state is CheckoutProcessing;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850, maxHeight: 600),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT SIDE - PAYMENT INTERACTION
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'selectPaymentMethod'.tr(context),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Tab Selector
                        Row(
                          children: [
                            _buildPaymentMethodTab(
                              method: PaymentMethod.cash,
                              icon: Icons.payments_outlined,
                              label: 'cash'.tr(context),
                            ),
                            const SizedBox(width: 8),
                            _buildPaymentMethodTab(
                              method: PaymentMethod.card,
                              icon: Icons.credit_card_outlined,
                              label: 'card'.tr(context),
                            ),
                            const SizedBox(width: 8),
                            _buildPaymentMethodTab(
                              method: PaymentMethod.qrCode,
                              icon: Icons.qr_code_scanner_outlined,
                              label: 'qrScan'.tr(context),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Active Mode Layout
                        Expanded(
                          child: IndexedStack(
                            index: _selectedMethod.index,
                            children: [
                              // CASH CALCULATOR
                              _buildCashLayout(theme, isDark),
                              // CARD TERMINAL
                              _buildCardLayout(theme, isDark),
                              // QR WALLET
                              _buildQRLayout(theme, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const VerticalDivider(width: 1),

                // RIGHT SIDE - BILLING INVOICE SUMMARY
                Expanded(
                  flex: 2,
                  child: Container(
                    color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFFAF6F0),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'invoiceSummary'.tr(context),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Scrollable invoice items list
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.order.items.length,
                            itemBuilder: (context, index) {
                              final item = widget.order.items[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}x ${item.product.name}',
                                        style: theme.textTheme.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.formatUsd(item.totalPrice),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        
                        // Metrics panel (USD Only to keep layout compact)
                        _buildInvoiceRow('subtotal'.tr(context), CurrencyFormatter.formatUsd(widget.order.subtotal)),
                        if (widget.order.discountAmount > 0)
                          _buildInvoiceRow(
                            'discount'.tr(context),
                            '-${CurrencyFormatter.formatUsd(widget.order.discountAmount)}',
                            valueColor: theme.colorScheme.primary,
                          ),
                        _buildInvoiceRow('tax'.tr(context), CurrencyFormatter.formatUsd(widget.order.taxAmount)),
                        
                        const Divider(height: 20),
                        
                        // Split Total Payable Block (USD and KHR)
                        _buildInvoiceRow(
                          "${'total'.tr(context)} (USD)",
                          CurrencyFormatter.formatUsd(widget.order.total),
                          isBold: true,
                          fontSize: 16,
                          valueColor: theme.colorScheme.primary,
                        ),
                        _buildInvoiceRow(
                          "${'total'.tr(context)} (KHR)",
                          CurrencyFormatter.formatKhr(widget.order.total),
                          isBold: true,
                          fontSize: 16,
                          valueColor: theme.colorScheme.primary,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Submit Transaction
                        ElevatedButton(
                          onPressed: isProcessing || (_selectedMethod == PaymentMethod.cash && _amountPaid < widget.order.total)
                              ? null
                              : () {
                                  context.read<CheckoutBloc>().add(
                                        ProcessPayment(
                                          order: widget.order,
                                          paymentMethod: _selectedMethod,
                                          amountPaid: _selectedMethod == PaymentMethod.cash 
                                              ? _amountPaid 
                                              : widget.order.total,
                                        ),
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _selectedMethod == PaymentMethod.cash
                                      ? 'Complete Cash Sale'
                                      : 'Authorise & Charge',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodTab({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == method;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
            if (method != PaymentMethod.cash) {
              _amountPaid = widget.order.total;
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary 
                : (isDark ? const Color(0xFF1E1A18) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : (isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3)),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : theme.colorScheme.secondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashLayout(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Keyboard and input on the left
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount display box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF3EFE9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _amountPaid < widget.order.total 
                        ? theme.colorScheme.error 
                        : (isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${'tendered'.tr(context)}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      CurrencyFormatter.format(_amountPaid),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _amountPaid < widget.order.total ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Custom Numeric Keypad
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ...'123456789.0C'.split(''),
                  ].map((char) {
                    return ElevatedButton(
                      onPressed: () => _onKeypadPressed(char),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF26211F) : Colors.white,
                        foregroundColor: theme.textTheme.bodyLarge?.color,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                          ),
                        ),
                      ),
                      child: Text(
                        char,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),

        // Quick suggestions and calculations on the right
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exact Amount Shortcut
              OutlinedButton(
                onPressed: () => _onQuickCashSelected(widget.order.total),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: theme.colorScheme.primary.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
                child: Text(
                  'Exact: ${CurrencyFormatter.format(widget.order.total)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // USD Bills
              Text(
                'USD BILLS', 
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [5.0, 10.0, 20.0, 50.0, 100.0].map((val) {
                  return SizedBox(
                    width: 68,
                    child: OutlinedButton(
                      onPressed: () => _onQuickCashSelected(val),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '\$${val.toStringAsFixed(0)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              
              // Riel Bills
              Text(
                'RIEL BILLS', 
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [10000.0, 20000.0, 50000.0, 100000.0].map((khrVal) {
                  final usdEquivalent = khrVal / CurrencyFormatter.usdToKhrRate;
                  return SizedBox(
                    width: 68,
                    child: OutlinedButton(
                      onPressed: () => _onQuickCashSelected(usdEquivalent),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '${(khrVal / 1000).toStringAsFixed(0)}k ៛', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const Spacer(),
              
              // Change returned preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('changeDue'.tr(context).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(_changeDue),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardLayout(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contactless_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'waitingTerminal'.tr(context),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'terminalInstructions'.tr(context),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRLayout(ThemeData theme, bool isDark) {
    final usdTotal = CurrencyFormatter.formatUsd(widget.order.total);
    final khrTotal = CurrencyFormatter.formatKhr(widget.order.total);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Settings Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showApiSettings ? 'ABA PayWay Settings' : 'scanToPay'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showApiSettings = !_showApiSettings;
                  });
                },
                icon: Icon(
                  _showApiSettings ? Icons.qr_code_scanner : Icons.settings,
                  size: 16,
                ),
                label: Text(
                  _showApiSettings ? 'Show QR' : 'ABA Sandbox API',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_showApiSettings) ...[
            // API Credentials Fields
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF3EFE9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _merchantIdController,
                    decoration: const InputDecoration(
                      labelText: 'Merchant ID',
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key (Public)',
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    obscureText: true,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiSecretController,
                    decoration: const InputDecoration(
                      labelText: 'API Secret (Private)',
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    obscureText: true,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      // Save to Hive persistent settings
                      await LocalDatabase.saveSetting('aba_merchant_id', _merchantIdController.text.trim());
                      await LocalDatabase.saveSetting('aba_api_key', _apiKeyController.text.trim());
                      await LocalDatabase.saveSetting('aba_api_secret', _apiSecretController.text.trim());
                      
                      _generateDynamicQrCode();
                      
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ABA Sandbox settings saved!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Save & Fetch Dynamic QR'),
                  ),
                ],
              ),
            ),
            if (_teachConcatString.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF26211F) : const Color(0xFFEADFD3).withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '📚 How Signature is Signed:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Parameter Concat:\n"$_teachConcatString"',
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 9),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2. HMAC-SHA512 Base64 Hash:\n"$_teachHash"',
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // KHQR CARD
            Container(
              width: 250,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF005A70), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1261C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'KHQR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Text(
                        'ABA Mobile',
                        style: TextStyle(
                          color: Color(0xFF005A70),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dynamic / Static QR code display
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _isLoadingQr
                          ? const SizedBox(
                              width: 140,
                              height: 140,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005A70)),
                                ),
                              ),
                            )
                          : Image.network(
                              Uri.https('api.qrserver.com', '/v1/create-qr-code/', {
                                'size': '250x250',
                                'data': _dynamicQrString ?? 'https://link.payway.com.kh/ABAPAYPd468685R',
                              }).toString(),
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: Center(
                                    child: Icon(Icons.qr_code_2, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Display Totals inside the Card
                  Text(
                    usdTotal,
                    style: const TextStyle(
                      color: Color(0xFF005A70),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    khrTotal,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (_qrError.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _qrError,
                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (_dynamicQrString == null) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo Mode: Tap gear settings icon to configure ABA Sandbox for dynamic generation.',
                        style: TextStyle(color: isDark ? Colors.blue[200] : Colors.blue[800], fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live Dynamic KHQR Code generated from ABA Sandbox API successfully!',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Text(
              'bakongGuide'.tr(context),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'instantCredit'.tr(context),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, double fontSize = 14, Color? valueColor}) {
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
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
