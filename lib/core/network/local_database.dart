import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/menu/domain/models/product.dart';
import '../../features/checkout/domain/models/order.dart';

class LocalDatabase {
  static const String _productsBoxName = 'pos_products';
  static const String _queuedOrdersBoxName = 'pos_queued_orders';
  static const String _salesBoxName = 'pos_sales';
  static const String _settingsBoxName = 'pos_settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_productsBoxName);
    await Hive.openBox(_queuedOrdersBoxName);
    await Hive.openBox(_salesBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // --- PRODUCTS CACHE ---
  static List<Product> getProducts() {
    final box = Hive.box(_productsBoxName);
    if (box.isEmpty) {
      return [];
    }
    return box.values
        .map((e) => Product.fromJson(Map<String, dynamic>.from(jsonDecode(e as String))))
        .toList();
  }

  static Future<void> saveProducts(List<Product> products) async {
    final box = Hive.box(_productsBoxName);
    await box.clear();
    for (var product in products) {
      await box.put(product.id, jsonEncode(product.toJson()));
    }
  }

  // --- QUEUED (HELD) ORDERS ---
  static List<Order> getQueuedOrders() {
    final box = Hive.box(_queuedOrdersBoxName);
    return box.values
        .map((e) => Order.fromJson(Map<String, dynamic>.from(jsonDecode(e as String))))
        .toList();
  }

  static Future<void> saveQueuedOrder(Order order) async {
    final box = Hive.box(_queuedOrdersBoxName);
    await box.put(order.id, jsonEncode(order.toJson()));
  }

  static Future<void> removeQueuedOrder(String orderId) async {
    final box = Hive.box(_queuedOrdersBoxName);
    await box.delete(orderId);
  }

  // --- COMPLETED ORDERS (SALES HISTORY) ---
  static List<Order> getSalesHistory() {
    final box = Hive.box(_salesBoxName);
    return box.values
        .map((e) => Order.fromJson(Map<String, dynamic>.from(jsonDecode(e as String))))
        .toList();
  }

  static Future<void> saveSale(Order order) async {
    final box = Hive.box(_salesBoxName);
    await box.put(order.id, jsonEncode(order.copyWith(status: OrderStatus.completed).toJson()));
  }

  static Future<void> clearAllData() async {
    await Hive.box(_productsBoxName).clear();
    await Hive.box(_queuedOrdersBoxName).clear();
    await Hive.box(_salesBoxName).clear();
    await Hive.box(_settingsBoxName).clear();
  }

  // --- PERSISTENT SETTINGS ---
  static String getSetting(String key, String defaultValue) {
    final box = Hive.box(_settingsBoxName);
    return box.get(key, defaultValue: defaultValue) as String;
  }

  static Future<void> saveSetting(String key, String value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(key, value);
  }
}
