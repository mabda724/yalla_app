import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/order_model.dart';

final riderProvider = StateNotifierProvider<RiderNotifier, RiderState>((ref) {
  return RiderNotifier(SupabaseService());
});

class RiderState {
  final bool isLoading;
  final bool isOnline;
  final double todayEarnings;
  final int todayDeliveries;
  final List<OrderModel> availableOrders;
  final OrderModel? activeDelivery;
  final String? error;

  const RiderState({
    this.isLoading = false,
    this.isOnline = false,
    this.todayEarnings = 0,
    this.todayDeliveries = 0,
    this.availableOrders = const [],
    this.activeDelivery,
    this.error,
  });

  RiderState copyWith({
    bool? isLoading,
    bool? isOnline,
    double? todayEarnings,
    int? todayDeliveries,
    List<OrderModel>? availableOrders,
    OrderModel? activeDelivery,
    String? error,
  }) {
    return RiderState(
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayDeliveries: todayDeliveries ?? this.todayDeliveries,
      availableOrders: availableOrders ?? this.availableOrders,
      activeDelivery: activeDelivery ?? this.activeDelivery,
      error: error,
    );
  }
}

class RiderNotifier extends StateNotifier<RiderState> {
  final SupabaseService _supabase;
  RiderNotifier(this._supabase) : super(const RiderState());

  Future<void> toggleOnline() async {
    final newStatus = !state.isOnline;
    final userId = _supabase.currentUser!.id;
    final riderRes = await _supabase.client.from('riders').select('id').eq('profile_id', userId).maybeSingle();
    if (riderRes != null) {
      await _supabase.client.from('riders').update({'is_online': newStatus}).eq('profile_id', userId);
    }
    state = state.copyWith(isOnline: newStatus);
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _supabase.client
          .from('orders')
          .select('*')
          .eq('status', 'ready')
          .order('created_at', ascending: false);
      final orders = (res as List).map((e) => OrderModel.fromMap(e)).toList();
      state = state.copyWith(isLoading: false, availableOrders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> acceptDelivery(String orderId) async {
    final userId = _supabase.currentUser!.id;
    final riderRes = await _supabase.client.from('riders').select('id').eq('profile_id', userId).single();
    final riderId = riderRes['id'] as String;

    await _supabase.client.from('orders').update({
      'rider_id': riderId,
      'status': 'rider_assigned',
    }).eq('id', orderId);

    final order = state.availableOrders.firstWhere((o) => o.id == orderId);
    state = state.copyWith(
      activeDelivery: order,
      availableOrders: state.availableOrders.where((o) => o.id != orderId).toList(),
    );
  }

  Future<void> updateDeliveryStatus(String status) async {
    if (state.activeDelivery == null) return;
    await _supabase.client.from('orders').update({'status': status}).eq('id', state.activeDelivery!.id);
    if (status == 'delivered') {
      state = state.copyWith(
        activeDelivery: null,
        todayDeliveries: state.todayDeliveries + 1,
        todayEarnings: state.todayEarnings + 5.0,
      );
    }
  }
}
