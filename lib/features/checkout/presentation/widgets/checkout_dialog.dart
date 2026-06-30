import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:js' as js;
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
import '../../../../core/utils/khqr_generator.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/utils/animations.dart';

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

  // Dynamic ABA QR / Bakong API Settings (loaded from static EnvConfig)
  final String _qrProvider = EnvConfig.defaultQrProvider;
  bool _isLoadingQr = false;
  String? _dynamicQrString;
  String _qrError = '';

  Timer? _bakongPollingTimer;
  bool _isCheckingBakong = false;

  void _startBakongPolling(String qrString) {
    _stopBakongPolling();
    if (EnvConfig.bakongToken.isEmpty) {
      debugPrint('Bakong Bearer Token is empty. Automatic polling disabled.');
      return;
    }

    final md5Hash = md5.convert(utf8.encode(qrString)).toString();
    debugPrint('Starting Bakong API Polling for MD5: $md5Hash');

    _bakongPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isCheckingBakong && _selectedMethod == PaymentMethod.qrCode) {
        _checkBakongPayment(md5Hash);
      }
    });
  }

  void _stopBakongPolling() {
    _bakongPollingTimer?.cancel();
    _bakongPollingTimer = null;
  }

  String _pollingStatusMessage = 'Waiting for payment...';
  String? _pollingError;

  Future<void> _checkBakongPayment(String md5Hash) async {
    final rawUrl = '${EnvConfig.bakongApiBaseUrl}/v1/check_transaction_by_md5';
    final urlString = EnvConfig.corsProxyUrl.isNotEmpty ? '${EnvConfig.corsProxyUrl}$rawUrl' : rawUrl;
    final url = Uri.parse(urlString);
    
    _isCheckingBakong = true;
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${EnvConfig.bakongToken}',
        },
        body: jsonEncode({
          'md5': md5Hash,
        }),
      );

      if (!mounted || _selectedMethod != PaymentMethod.qrCode) {
        _stopBakongPolling();
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> resData = jsonDecode(response.body);
        
        setState(() {
          _pollingError = null;
          if (resData['responseCode'] == 0) {
            final data = resData['data'];
            if (data != null) {
              _pollingStatusMessage = 'Payment received! Amount: ${data['amount']} ${data['currency']}';
            } else {
              _pollingStatusMessage = 'Payment confirmed!';
            }
          } else {
            // responseCode != 0 means transaction not found on server yet (normal until they scan and pay)
            _pollingStatusMessage = 'QR code generated. Waiting for payment...';
          }
        });

        if (resData['responseCode'] == 0 && resData['data'] != null) {
          _stopBakongPolling();
          _confirmQrPayment();
        }
      } else {
        String errorMsg = response.body;
        if (errorMsg.contains('<html') || errorMsg.contains('<HTML')) {
          errorMsg = 'Request blocked by Cloudflare/WAF (403 Forbidden).';
        }
        setState(() {
          _pollingError = 'API Response ${response.statusCode}: $errorMsg';
        });
        debugPrint('Bakong Polling Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      setState(() {
        _pollingError = 'Network error: $e';
      });
      debugPrint('Bakong API Polling exception: $e');
    } finally {
      _isCheckingBakong = false;
    }
  }

  void _confirmQrPayment() {
    context.read<CheckoutBloc>().add(
          ProcessPayment(
            order: widget.order,
            paymentMethod: PaymentMethod.qrCode,
            amountPaid: widget.order.total,
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    // Default cash amount paid is the exact total
    _amountPaid = widget.order.total;

    // Auto-fetch dynamic QR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateDynamicQrCode();
    });
  }

  @override
  void dispose() {
    _stopBakongPolling();
    super.dispose();
  }

  Future<void> _generateDynamicQrCode() async {
    if (_qrProvider == 'bakong') {
      final accountId = EnvConfig.bakongAccountId;
      final merchantName = EnvConfig.bakongMerchantName;
      final merchantCity = EnvConfig.bakongMerchantCity;

      if (accountId.isEmpty || merchantName.isEmpty) {
        setState(() {
          _dynamicQrString = null;
          _qrError = 'Please configure Bakong Account ID and Merchant Name in EnvConfig';
        });
        return;
      }

      setState(() {
        _isLoadingQr = true;
        _qrError = '';
      });

      try {
        final amount = widget.order.total;
        final orderNumber = 'pos_${widget.order.orderNumber}';

        // 1. Generate standard EMVCo KHQR payload locally
        final qrPayload = KhqrGenerator.generate(
          accountId: accountId,
          merchantName: merchantName,
          merchantCity: merchantCity,
          amount: amount,
          orderNumber: orderNumber,
        );

        setState(() {
          _dynamicQrString = qrPayload;
          _isLoadingQr = false;
        });
        if (_selectedMethod == PaymentMethod.qrCode && qrPayload.isNotEmpty) {
          _startBakongPolling(qrPayload);
        }
      } catch (e) {
        setState(() {
          _qrError = 'Failed to generate KHQR locally: $e';
          _isLoadingQr = false;
        });
      }
    } else {
      // Call ABA PayWay endpoint
      await _fetchAbaPayWayQrCode();
    }
  }

  Future<void> _fetchAbaPayWayQrCode() async {
    final merchantId = EnvConfig.abaMerchantId;
    final apiKey = EnvConfig.abaApiKey;
    final apiSecret = EnvConfig.abaApiSecret;

    if (merchantId.isEmpty || apiSecret.isEmpty) {
      setState(() {
        _dynamicQrString = null;
        _qrError = 'Please configure ABA credentials in EnvConfig';
      });
      return;
    }

    setState(() {
      _isLoadingQr = true;
      _qrError = '';
    });

    try {
      final reqTime = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
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

      // 3. SEND POST REQUEST TO ABA PAYWAY SANDBOX
      final url = Uri.parse('https://checkout-sandbox.payway.com.kh/api/payment-gateway/v1/payments/generate-qr');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
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
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: (1.0 - value) * 0.4,
                              child: Transform.scale(
                                scale: value,
                                child: child,
                              ),
                            );
                          },
                          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                        ),
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
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0.0, (1.0 - value) * 24),
                              child: child,
                            ),
                          );
                        },
                        child: ModernReceiptCard(order: state.order),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final receiptCard = ModernReceiptCard(order: state.order);
                              final fullUrl = receiptCard.buildInvoiceQrData();
                              final dataParam = fullUrl.split('?data=').last;
                              final localInvoiceUrl = 'invoice.html?data=$dataParam';
                              if (kIsWeb) {
                                if (js.context['printInvoiceInIframe'] == null) {
                                  final document = js.context['document'];
                                  final script = document.callMethod('createElement', ['script']);
                                  script['text'] = """
                                    window.printInvoiceInIframe = function(invoiceDataUrl) {
                                      const iframe = document.createElement('iframe');
                                      iframe.style.position = 'fixed';
                                      iframe.style.width = '0';
                                      iframe.style.height = '0';
                                      iframe.style.border = 'none';
                                      iframe.src = invoiceDataUrl;
                                      document.body.appendChild(iframe);
                                      iframe.onload = function() {
                                        setTimeout(() => {
                                          iframe.contentWindow.focus();
                                          iframe.contentWindow.print();
                                          setTimeout(() => {
                                            document.body.removeChild(iframe);
                                          }, 2000);
                                        }, 500);
                                      };
                                    };
                                  """;
                                  document['head'].callMethod('appendChild', [script]);
                                }
                                js.context.callMethod('printInvoiceInIframe', [localInvoiceUrl]);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Printing is only supported on Web: $localInvoiceUrl'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
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
        final size = MediaQuery.of(context).size;
        final isMobile = size.width < 750;

        if (isMobile) {
          final activeLayout = AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: KeyedSubtree(
              key: ValueKey<PaymentMethod>(_selectedMethod),
              child: _selectedMethod == PaymentMethod.cash
                  ? _buildCashLayout(theme, isDark, true)
                  : (_selectedMethod == PaymentMethod.card
                      ? _buildCardLayout(theme, isDark)
                      : _buildQRLayout(theme, isDark)),
            ),
          );

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: size.height * 0.9,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title and Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'selectPaymentMethod'.tr(context),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick total payable block card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFFAF6F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${'total'.tr(context)} (USD)",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                CurrencyFormatter.formatUsd(widget.order.total),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatKhr(widget.order.total),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Method selector tabs
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

                    // Payment layout
                    activeLayout,
                    const SizedBox(height: 24),

                    // Process Checkout button
                    ElevatedButton(
                      onPressed: isProcessing || (_selectedMethod == PaymentMethod.cash && _amountPaid < widget.order.total)
                          ? null
                          : () {
                              if (_selectedMethod == PaymentMethod.qrCode) {
                                _confirmQrPayment();
                              } else {
                                context.read<CheckoutBloc>().add(
                                      ProcessPayment(
                                        order: widget.order,
                                        paymentMethod: _selectedMethod,
                                        amountPaid: _selectedMethod == PaymentMethod.cash 
                                            ? _amountPaid 
                                            : widget.order.total,
                                      ),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  : (_selectedMethod == PaymentMethod.qrCode
                                      ? 'Confirm Success on App Bakong'
                                      : 'Authorise & Charge'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: KeyedSubtree(
                              key: ValueKey<PaymentMethod>(_selectedMethod),
                              child: _selectedMethod == PaymentMethod.cash
                                  ? _buildCashLayout(theme, isDark, false)
                                  : (_selectedMethod == PaymentMethod.card
                                      ? _buildCardLayout(theme, isDark)
                                      : _buildQRLayout(theme, isDark)),
                            ),
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
                                  if (_selectedMethod == PaymentMethod.qrCode) {
                                    _confirmQrPayment();
                                  } else {
                                    context.read<CheckoutBloc>().add(
                                          ProcessPayment(
                                            order: widget.order,
                                            paymentMethod: _selectedMethod,
                                            amountPaid: _selectedMethod == PaymentMethod.cash 
                                                ? _amountPaid 
                                                : widget.order.total,
                                          ),
                                        );
                                  }
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
                                      : (_selectedMethod == PaymentMethod.qrCode
                                          ? 'Confirm Success on App Bakong'
                                          : 'Authorise & Charge'),
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
      child: ScaleBouncePressReaction(
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMethod = method;
              if (method != PaymentMethod.cash) {
                _amountPaid = widget.order.total;
              }
              if (method == PaymentMethod.qrCode && _dynamicQrString != null && _dynamicQrString!.isNotEmpty) {
                _startBakongPolling(_dynamicQrString!);
              } else {
                _stopBakongPolling();
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
      ),
    );
  }

  Widget _buildCashLayout(ThemeData theme, bool isDark, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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

          // USD & Riel bills quick suggestions in a horizontal scrollable row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Exact
                OutlinedButton(
                  onPressed: () => _onQuickCashSelected(widget.order.total),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: theme.colorScheme.primary.withAlpha(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: Text(
                    'Exact: ${CurrencyFormatter.format(widget.order.total)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // USD
                ...[5.0, 10.0, 20.0, 50.0, 100.0].map((val) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: () => _onQuickCashSelected(val),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('\$${val.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  );
                }),
                // KHR
                ...[10000.0, 20000.0, 50000.0, 100000.0].map((khrVal) {
                  final usdEquivalent = khrVal / CurrencyFormatter.usdToKhrRate;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: OutlinedButton(
                      onPressed: () => _onQuickCashSelected(usdEquivalent),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('${(khrVal / 1000).toStringAsFixed(0)}k ៛', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Custom Numeric Keypad
          SizedBox(
            height: 180,
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 2.2, // wider aspect ratio for mobile keypad
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ...'123456789.0C'.split(''),
              ].map((char) {
                return ScaleBouncePressReaction(
                  child: ElevatedButton(
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
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Change returned preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('changeDue'.tr(context).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(
                  CurrencyFormatter.format(_changeDue),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

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
                    return ScaleBouncePressReaction(
                      child: ElevatedButton(
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

    Widget qrContent;

    if (_isLoadingQr) {
      qrContent = const SizedBox(
        width: 140,
        height: 140,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005A70)),
          ),
        ),
      );
    } else {
      // Always show QR code so they can scan
      qrContent = Image.network(
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
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                    Text(
                      _qrProvider == 'aba' ? 'ABA Mobile' : 'BAKONG KHQR',
                      style: const TextStyle(
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
                    child: qrContent,
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
          ],
          
          const SizedBox(height: 16),
          
          // Pending status text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005A70)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _pollingStatusMessage,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF7F3EE) : const Color(0xFF2C1B14),
                ),
              ),
            ],
          ),
          if (_pollingError != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _pollingError!,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Please scan and complete payment on your phone. The system is ready to confirm.',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFFA5968E) : const Color(0xFF6E5E57),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Action button
          ScaleBouncePressReaction(
            child: ElevatedButton.icon(
              onPressed: _confirmQrPayment,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                'Confirm Success on App Bakong',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ),
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
