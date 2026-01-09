import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  String? get currentUserId => currentUser?.id;

  String? get currentUserEmail => currentUser?.email;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('📝 Starting signup process...');
      print('📧 Email: $email');
      print('👤 Username: $username');

      print('⏳ Step 1: Creating auth account...');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      print('✅ Step 1 complete: Auth account created');

      if (response.user != null) {
        print('⏳ Step 2: Creating user profile in database...');

        await _createUserProfile(
          userId: response.user!.id,
          email: email,
          username: username,
        );

        print('✅ Step 2 complete: Profile created');
        print('🎉 Signup process complete! Safe to redirect now.');
      } else {
        print('⚠️ No user returned from signup');
      }

      return response;
    } catch (e) {
      print('❌ Signup failed: $e');
      throw Exception('Signup failed: $e');
    }
  }

  /// LOGIN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login...');
      print('📧 Email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('✅ Login successful');
      return response;
    } catch (e) {
      print('❌ Login failed: $e');
      throw Exception('Login failed: $e');
    }
  }

  /// LOGOUT
  Future<void> signOut() async {
    try {
      print('👋 Logging out...');
      await _supabase.auth.signOut();
      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout failed: $e');
      throw Exception('Logout failed: $e');
    }
  }

  /// Create user profile in database
  /// This runs automatically after signup
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String username,
  }) async {
    try {
      print('📊 Creating profile for user: $userId');

      final existingProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        print('📝 Inserting new profile into database...');
        await _supabase.from('profiles').insert({
          'id': userId,
          'email': email,
          'username': username,
          'total_score': 0,
          'tasks_completed': 0,
          'current_streak': 0,
          'longest_streak': 0,
        });

        print('✅ Profile created successfully for $email');

        // Verify profile was created
        final verifyProfile = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (verifyProfile == null) {
          throw Exception('Profile creation verification failed');
        }

        print('✅ Profile verified in database');
      } else {
        print('ℹ️ Profile already exists for $email');
      }
    } catch (e) {
      print('❌ Error creating profile: $e');
      // IMPORTANT: Throw error so signup knows it failed
      throw Exception('Profile creation failed: $e');
    }
  }

  /// Auto update UI
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}