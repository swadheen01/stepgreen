import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../auth/auth_service.dart';
import '../widgets/stat_card.dart';  // ← Import the reusable widget
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  String userName = "Loading...";
  String userEmail = "";
  int totalScore = 0;
  int tasksCompleted = 0;
  int currentStreak = 0;
  int longestStreak = 0;
  String memberSince = "";
  bool isLoading = true;
  bool isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Load profile data from database
  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('👤 Loading profile data...');

      // Get profile from database
      final profile = await _dbService.getUserProfile();

      if (profile != null) {
        // Format date
        DateTime createdDate = DateTime.parse(profile['created_at']);
        String formattedDate = '${_getMonthName(createdDate.month)} ${createdDate.year}';

        setState(() {
          userName = profile['username'] ?? 'User';
          userEmail = profile['email'] ?? '';
          totalScore = profile['total_score'] ?? 0;
          tasksCompleted = profile['tasks_completed'] ?? 0;
          currentStreak = profile['current_streak'] ?? 0;
          longestStreak = profile['longest_streak'] ?? 0;
          memberSince = formattedDate;
          isLoading = false;
        });

        print('✅ Profile loaded: $userName');
      } else {
        setState(() {
          isLoading = false;
        });
        print('❌ Profile not found');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('❌ Error loading profile: $e');
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Show delete account confirmation dialog
  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 48,
          ),
          title: const Text(
            'Delete Account?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 12),
              Text('This will permanently delete:'),
              SizedBox(height: 8),
              Text('• Your profile and account'),
              Text('• All your completed tasks'),
              Text('• Your scores and progress'),
              Text('• Your streak records'),
              Text('• All your game scores'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _handleDeleteAccount();
    }
  }

  /// Handle account deletion
  Future<void> _handleDeleteAccount() async {
    setState(() {
      isDeletingAccount = true;
    });

    try {
      print('🗑️ Starting account deletion process...');

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
              onWillPop: () async => false,
              child: const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Deleting your account...'),
                  ],
                ),
              ),
            );
          },
        );
      }

      // Get current user ID
      final userId = _authService.currentUserId;

      if (userId == null) {
        throw Exception('No user logged in');
      }

      print('🗑️ Deleting user data for: $userId');

      print('⏳ Step 1: Deleting completed tasks...');
      await Supabase.instance.client
          .from('user_tasks')
          .delete()
          .eq('user_id', userId);
      print('✅ Step 1 complete');

      print('⏳ Step 2: Deleting game scores...');
      await Supabase.instance.client
          .from('game_scores')
          .delete()
          .eq('user_id', userId);
      print('✅ Step 2 complete');

      print('⏳ Step 3: Deleting profile...');
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', userId);
      print('✅ Step 3 complete');

      print('⏳ Step 4: Deleting from Supabase Auth...');
      try {
        await Supabase.instance.client.rpc('delete_user');
        print('✅ Step 4 complete - User deleted from auth');
      } catch (e) {
        print('⚠️ RPC failed: $e');
        await _authService.signOut();
        print('✅ User signed out (auth record may remain)');
      }
      print('✅ Account deletion complete!');

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('❌ Error deleting account: $e');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        isDeletingAccount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF66BB6A),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile Picture
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Member since $memberSince',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Stats Grid - USING REUSABLE STATCARD WIDGET ✅
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    label: 'Total Score',
                    value: '$totalScore',
                    icon: Icons.eco,
                    color: const Color(0xFF2E7D32),
                  ),
                  StatCard(
                    label: 'Tasks Done',
                    value: '$tasksCompleted',
                    icon: Icons.check_circle,
                    color: Colors.blue,
                  ),
                  StatCard(
                    label: 'Current Streak',
                    value: '$currentStreak days',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                  StatCard(
                    label: 'Longest Streak',
                    value: '$longestStreak days',
                    icon: Icons.emoji_events,
                    color: Colors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    Icons.edit,
                    'Edit Profile',
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.notifications,
                    'Notifications',
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.help,
                    'Help & Support',
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon!')),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.delete_forever,
                    'Delete Account',
                    isDeletingAccount ? () {} : _showDeleteAccountDialog,
                    color: Colors.red,
                  ),
                  // ✅ FIXED LOGOUT METHOD
                  _buildSettingsItem(
                    Icons.logout,
                    'Logout',
                        () async {
                      try {
                        await _authService.signOut();

                        // ✅ Navigate to login and clear all previous routes
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                                (route) => false, // Remove all routes from stack
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: $e')),
                          );
                        }
                      }
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ❌ DELETED: _buildStatCard() - No longer needed
  // using reusable StatCard

  Widget _buildSettingsItem(
      IconData icon,
      String title,
      VoidCallback onTap, {
        Color? color,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}