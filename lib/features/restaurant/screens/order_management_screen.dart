import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_card.dart';
import '../../../core/widgets/neubrutalism_button.dart';
import '../providers/restaurant_provider.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantProvider);
    final pendingOrders = state.orders.where((o) => o.status == 'pending').toList();
    final activeOrders = state.orders.where((o) => o.status == 'accepted' || o.status == 'preparing' || o.status == 'ready').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الطلبات')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingOrders.isNotEmpty) ...[
              Row(
                children: [
                  const Text('🆕', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text('طلبات جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Text('${pendingOrders.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...pendingOrders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.payment, size: 14, color: AppColors.greyDark),
                          const SizedBox(width: 4),
                          Text(order.paymentMethod == 'cod' ? '💵 كاش' : '💳 مدفوع', style: const TextStyle(fontSize: 12, color: AppColors.greyDark)),
                          const Spacer(),
                          Text(order.createdAt.toString().substring(11, 16), style: const TextStyle(fontSize: 12, color: AppColors.greyDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: NeoButton(
                                label: '🛑 رفض',
                                backgroundColor: AppColors.error,
                                onPressed: () => ref.read(restaurantProvider.notifier).updateOrderStatus(order.id, 'cancelled'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: NeoButton(
                                label: '✅ قبول',
                                backgroundColor: AppColors.success,
                                onPressed: () => ref.read(restaurantProvider.notifier).updateOrderStatus(order.id, 'accepted'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            ],
            if (activeOrders.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('🔄 جاري التجهيز', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...activeOrders.map((order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NeoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatusChip(status: order.status),
                          const Spacer(),
                          if (order.status == 'accepted')
                            SizedBox(
                              height: 36,
                              child: NeoButton(
                                label: '✅ جاهز',
                                backgroundColor: AppColors.primary,
                                onPressed: () => ref.read(restaurantProvider.notifier).updateOrderStatus(order.id, 'ready'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      'accepted' => ('تم القبول', AppColors.secondary),
      'preparing' => ('جاري التجهيز', AppColors.warning),
      'ready' => ('جاهز', AppColors.success),
      _ => (status, AppColors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: data.$2, width: 1.5),
      ),
      child: Text(data.$1, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: data.$2)),
    );
  }
}
