import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_card.dart';
import '../../../models/restaurant_model.dart';

final restaurantListProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final supabase = SupabaseService();
  final response = await supabase.client
      .from('restaurants')
      .select('*')
      .eq('status', 'active')
      .eq('is_open', true)
      .order('avg_rating', ascending: false);
  return (response as List).map((e) => RestaurantModel.fromMap(e)).toList();
});

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('يالا'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MoodBar(),
            const SizedBox(height: 20),
            const Text(
              'المطاعم المفتوحة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            restaurantsAsync.when(
              data: (restaurants) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: restaurants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _RestaurantCard(restaurant: restaurants[index]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('$err')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'بحث'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'طلباتي'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'المفضلة'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final moods = [
      ('⚡', 'سريع'),
      ('🥗', 'صحي'),
      ('🍰', 'حلو'),
      ('💰', 'أقل سعر'),
      ('🌙', 'ليل متأخر'),
      ('🚀', 'جديد'),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 2.5),
            ),
            child: Row(
              children: [
                Text(moods[index].$1, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  moods[index].$2,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      onTap: () => Navigator.pushNamed(context, '/restaurant', arguments: restaurant.id),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: restaurant.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(restaurant.logoUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.restaurant, size: 36, color: AppColors.greyDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.nameAr ?? restaurant.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (restaurant.avgRating != null) ...[
                      const Icon(Icons.star, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.avgRating!.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.access_time, size: 14, color: AppColors.greyDark),
                    const SizedBox(width: 4),
                    Text(
                      '${restaurant.avgPrepTime}-${restaurant.avgPrepTime + 10} دقيقة',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.greyDark),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.deliveryFee > 0 ? 'توصيل \$${restaurant.deliveryFee.toStringAsFixed(0)}' : 'توصيل مجاني',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: restaurant.deliveryFee > 0 ? AppColors.greyDark : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: AppColors.grey),
        ],
      ),
    );
  }
}
