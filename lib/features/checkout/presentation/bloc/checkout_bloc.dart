import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/local_database.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/models/order.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc() : super(CheckoutInitial()) {
    on<ProcessPayment>(_onProcessPayment);
    on<LoadSalesHistory>(_onLoadSalesHistory);
    on<ClearSalesHistory>(_onClearSalesHistory);
  }

  Future<void> _onProcessPayment(ProcessPayment event, Emitter<CheckoutState> emit) async {
    emit(CheckoutProcessing());
    try {
      // Simulate network lag / card reader response
      await Future.delayed(const Duration(milliseconds: 800));

      final completedOrder = event.order.copyWith(
        status: OrderStatus.completed,
        paymentMethod: event.paymentMethod,
        amountPaid: event.amountPaid,
        dateTime: DateTime.now(),
      );

      // Save to local database (sales history)
      await LocalDatabase.saveSale(completedOrder);

      // Push to Supabase in the background if configured
      if (SupabaseService.isConfigured) {
        SupabaseService.uploadOrder(completedOrder);
      }

      emit(CheckoutSuccess(completedOrder));
    } catch (e) {
      emit(CheckoutFailure(e.toString()));
    }
  }

  Future<void> _onLoadSalesHistory(LoadSalesHistory event, Emitter<CheckoutState> emit) async {
    try {
      final sales = LocalDatabase.getSalesHistory();
      emit(SalesHistoryLoaded(sales));
    } catch (e) {
      emit(CheckoutFailure(e.toString()));
    }
  }

  Future<void> _onClearSalesHistory(ClearSalesHistory event, Emitter<CheckoutState> emit) async {
    try {
      // Clear data using Box clear inside LocalDatabase helper
      await LocalDatabase.clearAllData();
      emit(const SalesHistoryLoaded([]));
    } catch (e) {
      emit(CheckoutFailure(e.toString()));
    }
  }
}
