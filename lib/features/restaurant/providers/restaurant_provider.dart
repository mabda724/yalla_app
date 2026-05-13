import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/order_model.dart';

final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  return RestaurantNotifier(SupabaseService());
});

class RestaurantState {
  final bool isLoading;
  final RestaurantModel? restaurant;
  final List<MenuCategoryModel> menu;
  final List<OrderModel> orders;
  final int todayOrders;
  final double todayRevenue;
  final String? error;

  const RestaurantState({
    this.isLoading = false,
    this.restaurant,
    this.menu = const [],
    this.orders = const [],
    this.todayOrders = 0,
    this.todayRevenue = 0,
    this.error,
  });

  RestaurantState copyWith({
    bool? isLoading,
    RestaurantModel? restaurant,
    List<MenuCategoryModel>? menu,
    List<OrderModel>? orders,
    int? todayOrders,
    double? todayRevenue,
    String? error,
  }) {
    return RestaurantState(
      isLoading: isLoading ?? this.isLoading,
      restaurant: restaurant ?? this.restaurant,
      menu: menu ?? this.menu,
      orders: orders ?? this.orders,
      todayOrders: todayOrders ?? this.todayOrders,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      error: error,
    );
  }
}

class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final SupabaseService _supabase;
  RestaurantNotifier(this._supabase) : super(const RestaurantState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = _supabase.currentUser!.id;
      final res = await _supabase.client
          .from('restaurants')
          .select('*')
          .eq('owner_id', userId)
          .single();
      final restaurant = RestaurantModel.fromMap(res);

      final menuRes = await _supabase.client
          .from('menu_categories')
          .select('*, menu_items(*)')
          .eq('restaurant_id', restaurant.id)
          .order('sort_order');
      final menu = (menuRes as List).map((e) {
        final cat = MenuCategoryModel.fromMap(e);
        final items = (e['menu_items'] as List?)?.map((i) => MenuItemModel.fromMap(i)).toList() ?? [];
        return MenuCategoryModel(
          id: cat.id,
          restaurantId: cat.restaurantId,
          name: cat.name,
          nameAr: cat.nameAr,
          sortOrder: cat.sortOrder,
          isAvailable: cat.isAvailable,
          items: items,
        );
      }).toList();

      final ordersRes = await _supabase.client
          .from('orders')
          .select('*')
          .eq('restaurant_id', restaurant.id)
          .order('created_at', ascending: false)
          .limit(50);
      final orders = (ordersRes as List).map((e) => OrderModel.fromMap(e)).toList();

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final todayOrders = orders.where((o) => o.createdAt.toIso8601String().substring(0, 10) == today).length;
      final todayRevenue = orders
          .where((o) => o.createdAt.toIso8601String().substring(0, 10) == today && o.status == 'delivered')
          .fold(0.0, (sum, o) => sum + o.totalAmount);

      state = RestaurantState(
        restaurant: restaurant,
        menu: menu,
        orders: orders,
        todayOrders: todayOrders,
        todayRevenue: todayRevenue,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleOpen() async {
    if (state.restaurant == null) return;
    final newStatus = !state.restaurant!.isOpen;
    await _supabase.client
        .from('restaurants')
        .update({'is_open': newStatus})
        .eq('id', state.restaurant!.id);
    state = state.copyWith(
      restaurant: RestaurantModel(
        id: state.restaurant!.id,
        ownerId: state.restaurant!.ownerId,
        name: state.restaurant!.name,
        nameAr: state.restaurant!.nameAr,
        isOpen: newStatus,
        status: state.restaurant!.status,
        commissionRate: state.restaurant!.commissionRate,
        deliveryFee: state.restaurant!.deliveryFee,
        minOrderAmount: state.restaurant!.minOrderAmount,
        avgPrepTime: state.restaurant!.avgPrepTime,
      ),
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase.client.from('orders').update({'status': status}).eq('id', orderId);
    final updated = state.orders.map((o) => o.id == orderId ? OrderModel(id: o.id, customerId: o.customerId, restaurantId: o.restaurantId, status: status, subtotal: o.subtotal, totalAmount: o.totalAmount, paymentMethod: o.paymentMethod, createdAt: o.createdAt) : o).toList();
    state = state.copyWith(orders: updated);
  }
}
