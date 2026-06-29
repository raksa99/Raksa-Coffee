import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/local_database.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/repositories/menu_repository.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository menuRepository;

  MenuBloc({required this.menuRepository}) : super(MenuLoading()) {
    on<LoadMenu>(_onLoadMenu);
    on<SelectCategory>(_onSelectCategory);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onLoadMenu(LoadMenu event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final products = await menuRepository.getProducts();
      final rawCategories = await menuRepository.getCategories();
      final categories = ['All', ...rawCategories];
      emit(MenuLoaded(
        allProducts: products,
        categories: categories,
        selectedCategory: 'All',
      ));
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<MenuState> emit) {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;
      emit(MenuLoaded(
        allProducts: currentState.allProducts,
        categories: currentState.categories,
        selectedCategory: event.category,
      ));
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<MenuState> emit) async {
    try {
      // 1. Remove from local Hive database
      final currentProducts = LocalDatabase.getProducts();
      final updatedProducts = currentProducts.where((p) => p.id != event.productId).toList();
      await LocalDatabase.saveProducts(updatedProducts);

      // 2. Remove from Supabase cloud database (run async in background)
      if (SupabaseService.isConfigured) {
        SupabaseService.deleteProduct(event.productId);
      }

      // 3. Reload menu list to update UI
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }
}
