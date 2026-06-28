import '../models/product.dart';

abstract class MenuRepository {
  Future<List<Product>> getProducts();
  Future<List<String>> getCategories();
}
