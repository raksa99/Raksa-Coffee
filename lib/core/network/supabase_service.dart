import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../config/env_config.dart';
import '../../features/menu/domain/models/product.dart';
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
      
      await client.storage.from('product-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$extension',
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from('product-images').getPublicUrl(fileName);
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
}
