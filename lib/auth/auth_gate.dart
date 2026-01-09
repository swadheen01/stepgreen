import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../services/database_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final DatabaseService _dbService = DatabaseService();
  bool _isCheckingProfile = false;
  Future<bool> _checkProfileExists(String userId) async {
    try {
      print('🔍 AuthGate: Checking if profile exists for user: $userId');

      final profile = await _dbService.getUserProfile();

      if (profile != null) {
        print('✅ AuthGate: Profile exists, safe to show HomePage');
        return true;
      } else {
        print('⚠️ AuthGate: Profile not found, waiting...');
        return false;
      }
    } catch (e) {
      print('❌ AuthGate: Error checking profile: $e');
      return false;
    }
  }

  Future<bool> _waitForProfile(String userId) async {
    print('⏳ AuthGate: Waiting for profile to be created...');

    for (int i = 0; i < 20; i++) {
      final exists = await _checkProfileExists(userId);
      if (exists) {
        return true;
      }

      // Wait 500ms before trying again
      await Future.delayed(const Duration(milliseconds: 500));
      print('⏳ AuthGate: Retry ${i + 1}/20...');
    }

    print('❌ AuthGate: Timeout waiting for profile');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          final userId = session.user.id;

          print('👤 AuthGate: User logged in: $userId');

          return FutureBuilder<bool>(
            future: _waitForProfile(userId),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Setting up your profile...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Profile check complete
              final profileExists = profileSnapshot.data ?? false;

              if (profileExists) {
                print('✅ AuthGate: Showing HomePage');
                return const HomePage();
              } else {
                print('❌ AuthGate: Profile not found, logging out');

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showProfileErrorAndLogout(context);
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        } else {
          print('🔓 AuthGate: No user logged in, showing LoginPage');
          return const LoginPage();
        }
      },
    );
  }


  void _showProfileErrorAndLogout(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Profile Error'),
        content: const Text(
          'Failed to create your profile. Please try signing up again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Log out
    await Supabase.instance.client.auth.signOut();
  }
}