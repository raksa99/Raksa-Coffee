import '../../domain/models/product.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/local_menu_datasource.dart';

class MenuRepositoryImpl implements MenuRepository {
  final LocalMenuDatasource _datasource;

  MenuRepositoryImpl(this._datasource);

  @override
  Future<List<Product>> getProducts() async {
    return _datasource.getProducts();
  }

  @override
  Future<List<String>> getCategories() async {
    return _datasource.getCategories();
  }
}
