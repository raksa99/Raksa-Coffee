import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/local_database.dart';
import '../../../menu/domain/models/modifier.dart';
import '../../../checkout/domain/models/order.dart';
import '../../domain/models/cart_item.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  static const _uuid = Uuid();

  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<ApplyDiscount>(_onApplyDiscount);
    on<HoldOrder>(_onHoldOrder);
    on<ResumeOrder>(_onResumeOrder);
    on<LoadQueuedOrdersList>(_onLoadQueuedOrders);
    on<DeleteQueuedOrder>(_onDeleteQueuedOrder);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final List<CartItem> updatedItems = List.from(state.items);
    
    // Check if an item with the exact same product and modifier selection already exists
    int existingIndex = -1;
    for (int i = 0; i < updatedItems.length; i++) {
      final existingItem = updatedItems[i];
      if (existingItem.product.id == event.item.product.id &&
          _areModifiersEqual(existingItem.selectedModifiers, event.item.selectedModifiers)) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      // Item exists, update its quantity
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + event.item.quantity,
      );
    } else {
      // Add as a new item
      updatedItems.add(event.item);
    }

    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateCartItemQuantity(UpdateCartItemQuantity event, Emitter<CartState> emit) {
    if (event.newQuantity <= 0) {
      add(RemoveFromCart(event.itemId));
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == event.itemId) {
        return item.copyWith(quantity: event.newQuantity);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updatedItems));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final updatedItems = state.items.where((item) => item.id != event.itemId).toList();
    emit(state.copyWith(items: updatedItems));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(state.copyWith(
      items: const [],
      discountValue: 0.0,
      discountType: DiscountType.percentage,
    ));
  }

  void _onApplyDiscount(ApplyDiscount event, Emitter<CartState> emit) {
    emit(state.copyWith(
      discountType: event.discountType,
      discountValue: event.discountValue,
    ));
  }

  Future<void> _onHoldOrder(HoldOrder event, Emitter<CartState> emit) async {
    if (state.items.isEmpty) {
      emit(state.copyWith(errorMessage: 'Cannot hold an empty cart'));
      return;
    }

    try {
      final dailyOrdersCount = LocalDatabase.getSalesHistory().length + LocalDatabase.getQueuedOrders().length + 1;
      final orderNumber = dailyOrdersCount.toString().padLeft(4, '0');

      final newOrder = Order(
        id: _uuid.v4(),
        orderNumber: orderNumber,
        items: state.items,
        discountType: state.discountType,
        discountValue: state.discountValue,
        taxRate: state.taxRate,
        dateTime: DateTime.now(),
        status: OrderStatus.queued,
        customerName: event.customerName.trim().isEmpty 
            ? 'Guest #${orderNumber.substring(2)}' 
            : event.customerName.trim(),
      );

      await LocalDatabase.saveQueuedOrder(newOrder);
      
      // Clear cart
      emit(state.copyWith(
        items: const [],
        discountValue: 0.0,
        discountType: DiscountType.percentage,
        isSuccess: true,
      ));

      // Reload queued orders list
      add(LoadQueuedOrdersList());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to hold order: $e'));
    }
  }

  Future<void> _onResumeOrder(ResumeOrder event, Emitter<CartState> emit) async {
    try {
      // Remove from the hold database
      await LocalDatabase.removeQueuedOrder(event.order.id);
      
      // Load into active cart state
      emit(state.copyWith(
        items: event.order.items,
        discountType: event.order.discountType,
        discountValue: event.order.discountValue,
        taxRate: event.order.taxRate,
      ));

      // Reload queued orders list
      add(LoadQueuedOrdersList());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to resume order: $e'));
    }
  }

  Future<void> _onLoadQueuedOrders(LoadQueuedOrdersList event, Emitter<CartState> emit) async {
    try {
      final orders = LocalDatabase.getQueuedOrders();
      emit(state.copyWith(queuedOrders: orders));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to load queued orders: $e'));
    }
  }

  Future<void> _onDeleteQueuedOrder(DeleteQueuedOrder event, Emitter<CartState> emit) async {
    try {
      await LocalDatabase.removeQueuedOrder(event.orderId);
      add(LoadQueuedOrdersList());
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete queued order: $e'));
    }
  }

  // Deep comparison of modifier selections
  bool _areModifiersEqual(
    Map<String, List<ModifierOption>> mods1,
    Map<String, List<ModifierOption>> mods2,
  ) {
    if (mods1.length != mods2.length) return false;

    for (var key in mods1.keys) {
      if (!mods2.containsKey(key)) return false;

      final list1 = mods1[key]!;
      final list2 = mods2[key]!;

      if (list1.length != list2.length) return false;

      // Extract ids and check equality
      final set1 = list1.map((e) => e.id).toSet();
      final set2 = list2.map((e) => e.id).toSet();

      if (set1.difference(set2).isNotEmpty) return false;
    }

    return true;
  }
}
