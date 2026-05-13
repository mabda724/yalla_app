import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_card.dart';
import '../../../core/widgets/neubrutalism_button.dart';
import '../providers/rider_provider.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(riderProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rider'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: state.activeDelivery != null
          ? _ActiveDeliveryView(state: state, ref: ref)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Online/Offline
                  NeoCard(
                    backgroundColor: state.isOnline ? AppColors.success : AppColors.greyLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: state.isOnline ? AppColors.success : AppColors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              state.isOnline ? 'متاح للتوصيل' : 'غير متاح',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Switch(
                          value: state.isOnline,
                          onChanged: (_) => ref.read(riderProvider.notifier).toggleOnline(),
                          activeTrackColor: AppColors.success,
                          inactiveThumbColor: AppColors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      Expanded(child: _StatCard(emoji: '💰', label: 'أرباح اليوم', value: '\$${state.todayEarnings.toStringAsFixed(0)}')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(emoji: '📦', label: 'توصيل اليوم', value: '${state.todayDeliveries}')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (state.isOnline) ...[
                    const Text('🆕 طلبات متاحة للتوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if (state.availableOrders.isEmpty)
                      const NeoCard(
                        child: Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('مافيش طلبات دلوقتي 🎉', style: TextStyle(fontSize: 16, color: AppColors.greyDark, fontWeight: FontWeight.w500)),
                        )),
                      )
                    else
                      ...state.availableOrders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NeoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.store, size: 14, color: AppColors.greyDark),
                                  const SizedBox(width: 4),
                                  Text('المطعم: ${order.restaurantId.substring(0, 8)}', style: const TextStyle(fontSize: 12, color: AppColors.greyDark)),
                                  const Spacer(),
                                  Text('约 2.5 كم', style: const TextStyle(fontSize: 12, color: AppColors.greyDark)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 44,
                                child: NeoButton(
                                  label: '🚀 أقبل التوصيل',
                                  backgroundColor: AppColors.secondary,
                                  onPressed: () => ref.read(riderProvider.notifier).acceptDelivery(order.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on_outlined), label: 'الأرباح'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}

class _ActiveDeliveryView extends StatelessWidget {
  final RiderState state;
  final WidgetRef ref;

  const _ActiveDeliveryView({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const NeoCard(
            backgroundColor: AppColors.secondary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🛵', style: TextStyle(fontSize: 32)),
                SizedBox(width: 12),
                Text('توصيلة نشطة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          NeoCard(
            child: Column(
              children: [
                const Text('تفاصيل الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _DetailRow(label: 'رقم الطلب', value: '#${state.activeDelivery!.id.substring(0, 8)}'),
                _DetailRow(label: 'المبلغ', value: '\$${state.activeDelivery!.totalAmount.toStringAsFixed(2)}'),
                _DetailRow(label: 'طريقة الدفع', value: state.activeDelivery!.paymentMethod == 'cod' ? '💵 كاش' : '💳 مدفوع'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NeoCard(
            child: Column(
              children: [
                const Text('حالة التوصيل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _StatusStep(label: 'تم الاستلام من المطعم', isDone: true),
                _StatusStep(label: 'في الطريق للعميل', isDone: false),
                _StatusStep(label: 'تم التوصيل', isDone: false),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: NeoOutlineButton(
                  label: '📞 العميل',
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeoButton(
                  label: '✅ تم التوصيل',
                  backgroundColor: AppColors.success,
                  onPressed: () => ref.read(riderProvider.notifier).updateDeliveryStatus('delivered'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final bool isDone;
  const _StatusStep({required this.label, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? AppColors.success : AppColors.greyLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDone ? AppColors.black : AppColors.grey)),
        ],
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
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.greyDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
