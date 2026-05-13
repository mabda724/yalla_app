import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_card.dart';
import '../../../core/widgets/neubrutalism_button.dart';
import '../providers/restaurant_provider.dart';

class MenuManagementScreen extends ConsumerWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('قائمتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: state.menu.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📝', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('القائمة فاضية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('أضف أقسام وأصناف', style: TextStyle(color: AppColors.greyDark)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.menu.length,
              itemBuilder: (context, index) {
                final cat = state.menu[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.nameAr ?? cat.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => _showAddItemDialog(context, ref, cat.id),
                            ),
                          ],
                        ),
                        if (cat.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('مافيش أصناف', style: TextStyle(color: AppColors.greyDark)),
                          )
                        else
                          ...cat.items.map((item) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.borderLight, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.nameAr ?? item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text('\$${item.basePrice.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  if (!item.isAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.error, width: 1),
                                      ),
                                      child: const Text('نفذ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
                                    ),
                                ],
                              ),
                            ),
                          )),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('قسم جديد', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اسم القسم (مثلاً: مشاوي)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          NeoButton(
            label: 'إضافة',
            onPressed: () async {
              final restaurant = ref.read(restaurantProvider).restaurant;
              if (controller.text.isNotEmpty && restaurant != null) {
                await ref.read(restaurantProvider.notifier).loadDashboard();
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref, String categoryId) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('صنف جديد', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'اسم الصنف')),
            const SizedBox(height: 12),
            TextField(controller: priceCtrl, decoration: const InputDecoration(hintText: 'السعر'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          NeoButton(
            label: 'إضافة',
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final restaurant = ref.read(restaurantProvider).restaurant;
                if (restaurant != null) {
                  await ref.read(restaurantProvider.notifier).loadDashboard();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
