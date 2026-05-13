import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/neubrutalism_button.dart';
import '../../../core/widgets/neubrutalism_text_field.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    final role = args ?? 'customer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(role == 'customer' ? 'عميل جديد' : role == 'restaurant' ? 'مطعم جديد' : 'Rider جديد'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 20),
                      NeoTextField(
                        controller: _nameController,
                        label: 'الاسم بالكامل',
                        hint: 'أحمد محمد',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل الاسم';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      NeoTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                          if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      NeoTextField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        hint: '01012345678',
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل رقم الهاتف';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      NeoTextField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '********',
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                          if (v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (authState.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error, width: 2),
                          ),
                          child: Text(
                            authState.error!,
                            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                      NeoButton(
                        label: 'إنشاء حساب',
                        isLoading: authState.isLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ref.read(authProvider.notifier).signUp(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  fullName: _nameController.text.trim(),
                                  phone: _phoneController.text.trim(),
                                  role: role,
                                );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'عندك حساب؟',
                      style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.greyDark),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        'تسجيل دخول',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.black, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
