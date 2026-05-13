import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(SupabaseService());
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? role;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.role,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? role,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      role: role ?? this.role,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabase;

  AuthNotifier(this._supabase) : super(const AuthState());

  Future<void> checkSession() async {
    if (_supabase.isLoggedIn) {
      final role = await _supabase.getUserRole();
      final user = _supabase.currentUser;
      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          role: role,
          user: UserModel(
            id: user.id,
            fullName: user.userMetadata?['full_name'] as String? ?? '',
            email: user.email,
            role: role ?? 'customer',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, role: role);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.signIn(email: email, password: password);
      final role = await _supabase.getUserRole();
      state = state.copyWith(isLoading: false, isAuthenticated: true, role: role);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _supabase.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
