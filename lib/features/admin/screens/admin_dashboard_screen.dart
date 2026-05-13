import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_card.dart';
import '../../../core/services/supabase_service.dart';

final adminProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = SupabaseService();
  final restaurants = await supabase.client.from('restaurants').select('status');
  final riders = await supabase.client.from('riders').select('verification_status');
  final todayOrders = await supabase.client
      .from('orders')
      .select('*')
      .gte('created_at', DateTime.now().toIso8601String().substring(0, 10));

  final r = (restaurants as List);
  final rd = (riders as List);
  final ord = (todayOrders as List);

  return {
    'total_restaurants': r.length,
    'pending_restaurants': r.where((e) => e['status'] == 'pending').length,
    'total_riders': rd.length,
    'pending_riders': rd.where((e) => e['verification_status'] == 'pending').length,
    'today_orders': ord.length,
    'today_revenue': ord.fold(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0)),
  };
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminProvider),
          ),
        ],
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('$err')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊 نظرة عامة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _AdminStatCard(emoji: '🏪', label: 'المطاعم', value: '${data['total_restaurants']}', sub: '${data['pending_restaurants']} في الانتظار')),
                  const SizedBox(width: 12),
                  Expanded(child: _AdminStatCard(emoji: '🛵', label: 'Riders', value: '${data['total_riders']}', sub: '${data['pending_riders']} في الانتظار')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _AdminStatCard(emoji: '📦', label: 'طلبات اليوم', value: '${data['today_orders']}', sub: '')),
                  const SizedBox(width: 12),
                  Expanded(child: _AdminStatCard(emoji: '💰', label: 'إيرادات اليوم', value: '\$${(data['today_revenue'] as double).toStringAsFixed(0)}', sub: '')),
                ],
              ),
              const SizedBox(height: 24),
              const Text('⚡ إجراءات سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _ActionTile(emoji: '🏪', label: 'مراجعة المطاعم الجديدة', count: data['pending_restaurants'] as int),
              const SizedBox(height: 8),
              _ActionTile(emoji: '🛵', label: 'مراجعة Riders جدد', count: data['pending_riders'] as int),
              const SizedBox(height: 8),
              _ActionTile(emoji: '📋', label: 'إدارة الطلبات', count: null),
              const SizedBox(height: 8),
              _ActionTile(emoji: '💰', label: 'التسويات المالية', count: null),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;

  const _AdminStatCard({required this.emoji, required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.greyDark)),
          if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int? count;

  const _ActionTile({required this.emoji, required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return NeoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          if (count != null && count! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          const Icon(Icons.chevron_left, color: AppColors.grey),
        ],
      ),
    );
  }
}
