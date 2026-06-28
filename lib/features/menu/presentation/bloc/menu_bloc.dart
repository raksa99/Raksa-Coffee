import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/menu_repository.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository menuRepository;

  MenuBloc({required this.menuRepository}) : super(MenuLoading()) {
    on<LoadMenu>(_onLoadMenu);
    on<SelectCategory>(_onSelectCategory);
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
}
