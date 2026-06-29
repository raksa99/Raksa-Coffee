import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../config/env_config.dart';
import '../../features/menu/domain/models/product.dart';
import '../../features/cart/domain/models/cart_item.dart';
import '../../features/checkout/domain/models/order.dart';
import 'local_database.dart';

class SupabaseService {
  static bool get isConfigured =>
      EnvConfig.supabaseUrl.isNotEmpty && EnvConfig.supabaseAnonKey.isNotEmpty;

  /// Initializes the Supabase client if keys are provided.
  static Future<void> init() async {
    if (!isConfigured) {
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        publishableKey: EnvConfig.supabaseAnonKey,
      );
    } catch (e) {
      // Quiet fail to avoid UI blocking
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  // ==========================================
  // PRODUCTS SYNC LOGIC
  // ==========================================

  /// Uploads a product image XFile to Supabase Storage and returns its public URL.
  static Future<String?> uploadProductImage(XFile file) async {
    if (!isConfigured) return null;

    try {
      final bytes = await file.readAsBytes();
      final extension = file.name.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      await client.storage.from('Product_image').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$extension',
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from('Product_image').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Pulls the latest products list from Supabase and overwrites local cache.
  static Future<List<Product>> pullProducts() async {
    if (!isConfigured) return [];

    try {
      final response = await client.from('products').select();
      
      final products = (response as List<dynamic>)
          .map((json) => Product.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Save to local Hive cache for offline support
      await LocalDatabase.saveProducts(products);
      return products;
    } catch (e) {
      // Fallback to local Hive cache
      return LocalDatabase.getProducts();
    }
  }

  /// Pushes a new product to the Supabase cloud table.
  static Future<void> pushProduct(Product product) async {
    if (!isConfigured) return;

    try {
      await client.from('products').upsert(product.toJson());
    } catch (e) {
      // Quiet fail in background
    }
  }

  /// Deletes a product from the Supabase cloud table.
  static Future<void> deleteProduct(String productId) async {
    if (!isConfigured) return;

    try {
      await client.from('products').delete().eq('id', productId);
    } catch (e) {
      // Quiet fail in background
    }
  }

  // ==========================================
  // ORDERS / SALES SYNC LOGIC
  // ==========================================

  /// Uploads a completed sale order to Supabase.
  static Future<bool> uploadOrder(Order order) async {
    if (!isConfigured) return false;

    try {
      await client.from('orders').upsert({
        'id': order.id,
        'order_number': order.orderNumber,
        'items': order.items.map((item) => item.toJson()).toList(),
        'total': order.total,
        'subtotal': order.subtotal,
        'discount': order.discountAmount,
        'payment_method': order.paymentMethod?.name,
        'status': order.status.name,
        'created_at': order.dateTime.toIso8601String(),
      });
      return true;
    } catch (e) {
      developer.log('Supabase uploadOrder error', error: e);
      return false;
    }
  }

  /// Iterates over local completed orders and uploads any unsynced sales.
  static Future<void> syncOfflineSales() async {
    if (!isConfigured) return;

    final localSales = LocalDatabase.getSalesHistory();
    if (localSales.isEmpty) return;

    for (var order in localSales) {
      await uploadOrder(order);
    }
  }

  /// Pulls completed sales orders from Supabase and saves them to local Hive database.
  static Future<List<Order>> pullOrders() async {
    if (!isConfigured) return [];

    try {
      final response = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      
      final List<Order> orders = [];
      for (var json in response as List<dynamic>) {
        try {
          final itemsList = (json['items'] as List<dynamic>)
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          final pMethod = PaymentMethod.values.firstWhere(
            (e) => e.name == json['payment_method'],
            orElse: () => PaymentMethod.cash,
          );

          final oStatus = OrderStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => OrderStatus.completed,
          );

          final order = Order(
            id: json['id'] as String,
            orderNumber: json['order_number'] as String? ?? '',
            items: itemsList,
            discountType: DiscountType.fixed,
            discountValue: (json['discount'] as num? ?? 0).toDouble(),
            taxRate: 0.08,
            paymentMethod: pMethod,
            amountPaid: (json['total'] as num? ?? 0).toDouble(),
            dateTime: DateTime.parse(json['created_at'] as String),
            status: oStatus,
            customerName: '',
          );
          orders.add(order);
        } catch (e) {
          // ignore parsing error for single order
        }
      }

      // Save to local Hive database to update cache
      if (orders.isNotEmpty) {
        await LocalDatabase.saveSales(orders);
      }
      return orders;
    } catch (e) {
      return [];
    }
  }
}
