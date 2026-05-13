import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_card.dart';
import '../providers/restaurant_provider.dart';

class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends ConsumerState<RestaurantDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(restaurantProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantProvider);
    final restaurant = state.restaurant;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(restaurant?.nameAr ?? restaurant?.name ?? 'المطعم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Online/Offline Toggle
                  NeoCard(
                    backgroundColor: restaurant?.isOpen == true ? AppColors.success : AppColors.error,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: restaurant?.isOpen == true ? AppColors.success : AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              restaurant?.isOpen == true ? 'المطعم مفتوح' : 'المطعم مغلق',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Switch(
                          value: restaurant?.isOpen ?? false,
                          onChanged: (_) => ref.read(restaurantProvider.notifier).toggleOpen(),
                          activeTrackColor: AppColors.success,
                          inactiveThumbColor: AppColors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(child: _StatCard(emoji: '📦', label: 'طلبات اليوم', value: '${state.todayOrders}')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(emoji: '💰', label: 'إيرادات اليوم', value: '\$${state.todayRevenue.toStringAsFixed(0)}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatCard(emoji: '📋', label: 'الأصناف', value: '${state.menu.fold(0, (sum, c) => sum + c.items.length)}')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(emoji: '⭐', label: 'التقييم', value: restaurant?.avgRating?.toStringAsFixed(1) ?? '0.0')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'الطلبات الجديدة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...state.orders.where((o) => o.status == 'pending' || o.status == 'accepted').take(5).map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NeoCard(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: order.status == 'pending' ? AppColors.warning : AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('#${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.greyDark)),
                              ],
                            ),
                          ),
                          Text(order.statusLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                  )),
                  if (state.orders.where((o) => o.status == 'pending').isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('مافيش طلبات جديدة 🎉', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.greyDark)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatCard({required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.greyDark)),
        ],
      ),
    );
  }
}
