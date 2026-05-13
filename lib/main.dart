import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/role_selection_screen.dart';
import 'features/customer/screens/home_screen.dart';
import 'features/customer/screens/cart_screen.dart';
import 'features/restaurant/screens/restaurant_nav_screen.dart';
import 'features/rider/screens/rider_home_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService().init();
  runApp(const ProviderScope(child: YallaApp()));
}

class YallaApp extends StatelessWidget {
  const YallaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'يالا',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            final role = settings.arguments as String? ?? 'customer';
            return MaterialPageRoute(
              builder: (_) => RegisterScreen(),
              settings: RouteSettings(arguments: role),
            );
          case '/role-selection':
            return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const CustomerHomeScreen());
          case '/cart':
            return MaterialPageRoute(builder: (_) => const CartScreen());
          case '/restaurant':
            return MaterialPageRoute(builder: (_) => const RestaurantNavScreen());
          case '/rider':
            return MaterialPageRoute(builder: (_) => const RiderHomeScreen());
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    final supabase = SupabaseService();
    if (supabase.isLoggedIn) {
      final role = await supabase.getUserRole();
      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'restaurant') {
        Navigator.pushReplacementNamed(context, '/restaurant');
      } else if (role == 'rider') {
        Navigator.pushReplacementNamed(context, '/rider');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD700),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Text(
                'يالا',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚡',
              style: TextStyle(fontSize: 48),
            ),
          ],
        ),
      ),
    );
  }
}
