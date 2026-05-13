import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_card.dart';
import '../../../core/widgets/neubrutalism_button.dart';
import '../../../models/order_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  void addItem(CartItemModel item) {
    final existingIndex = state.indexWhere((e) => e.itemId == item.itemId);
    if (existingIndex >= 0) {
      state[existingIndex].quantity += item.quantity;
      state = [...state];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void updateQuantity(String id, int qty) {
    if (qty <= 0) {
      removeItem(id);
      return;
    }
    final index = state.indexWhere((e) => e.id == id);
    if (index >= 0) {
      state[index].quantity = qty;
      state = [...state];
    }
  }

  void clear() => state = [];

  double get subtotal => state.fold(0, (sum, item) => sum + item.totalPrice);
  double get deliveryFee => subtotal > 50 ? 0 : 5;
  double get total => subtotal + deliveryFee;
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('سلة الطلب (${cart.length})'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text(
                'تفريغ',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🛒', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text(
                    'السلة فاضية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أضف أصناف من المطاعم',
                    style: TextStyle(color: AppColors.greyDark, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return NeoCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  if (item.variationName != null)
                                    Text(
                                      item.variationName!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.greyDark),
                                    ),
                                  Text(
                                    '\$${item.unitPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.black),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _QtyButton(
                                  icon: Icons.remove,
                                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 8),
                                _QtyButton(
                                  icon: Icons.add,
                                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _PriceRow(label: 'المجموع الفرعي', amount: ref.read(cartProvider.notifier).subtotal),
                      const SizedBox(height: 4),
                      _PriceRow(label: 'توصيل', amount: ref.read(cartProvider.notifier).deliveryFee),
                      const Divider(color: AppColors.border, thickness: 2, height: 20),
                      _PriceRow(
                        label: 'الإجمالي',
                        amount: ref.read(cartProvider.notifier).total,
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: NeoOutlineButton(
                              label: '💵 كاش',
                              onPressed: () => _checkout(ref, 'cod'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: NeoButton(
                              label: '💳 دفع',
                              backgroundColor: AppColors.secondary,
                              onPressed: () => _checkout(ref, 'instapay'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _checkout(WidgetRef ref, String method) {
    final cart = ref.read(cartProvider.notifier);
    if (cart.subtotal <= 0) return;
    ScaffoldMessenger.of(ref.context as BuildContext).showSnackBar(
      SnackBar(
        content: Text(method == 'cod' ? 'طلب كاش - سيتم الدفع عند الاستلام' : 'طلب InstaPay - سيتم تحويلك للدفع'),
        backgroundColor: AppColors.black,
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Icon(icon, size: 18, color: AppColors.black),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _PriceRow({required this.label, required this.amount, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? AppColors.black : AppColors.greyDark,
          ),
        ),
      ],
    );
  }
}
