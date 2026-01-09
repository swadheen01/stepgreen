import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;
  /// Get current user's profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) {
        print('❌ No user logged in');
        return null;
      }

      print('📡 Fetching profile for user: $currentUserId');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .single();

      print('✅ Profile loaded: ${response['username']}');
      return response;
    } catch (e) {
      print('❌ Error loading profile: $e');
      return null;
    }
  }

  Future<void> updateUserScore(int pointsToAdd) async {
    try {
      if (currentUserId == null) return;

      print('📡 Adding $pointsToAdd points to user score');

      final profile = await getUserProfile();
      if (profile == null) return;

      int currentScore = profile['total_score'] ?? 0;
      int newScore = currentScore + pointsToAdd;


      await _supabase.from('profiles').update({
        'total_score': newScore,
      }).eq('id', currentUserId!);

      print('✅ Score updated: $currentScore → $newScore');
    } catch (e) {
      print('❌ Error updating score: $e');
    }
  }

  /// Update tasks completed count
  Future<void> incrementTasksCompleted() async {
    try {
      if (currentUserId == null) return;

      print('📡 Incrementing tasks completed');

      final profile = await getUserProfile();
      if (profile == null) return;

      int currentCount = profile['tasks_completed'] ?? 0;
      int newCount = currentCount + 1;

      // Update in database
      await _supabase.from('profiles').update({
        'tasks_completed': newCount,
      }).eq('id', currentUserId!);

      print('✅ Tasks completed: $currentCount → $newCount');
    } catch (e) {
      print('❌ Error updating tasks: $e');
    }
  }

  /// Update user's streak
  Future<void> updateStreak(int newStreak) async {
    try {
      if (currentUserId == null) return;

      print('📡 Updating streak to $newStreak');

      final profile = await getUserProfile();
      if (profile == null) return;

      int longestStreak = profile['longest_streak'] ?? 0;

      if (newStreak > longestStreak) {
        longestStreak = newStreak;
      }

      await _supabase.from('profiles').update({
        'current_streak': newStreak,
        'longest_streak': longestStreak,
      }).eq('id', currentUserId!);

      print('✅ Streak updated: $newStreak (longest: $longestStreak)');
    } catch (e) {
      print('❌ Error updating streak: $e');
    }
  }


  Future<void> calculateAndUpdateStreak() async {
    try {
      if (currentUserId == null) return;

      print('📡 Calculating streak...');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Check if user completed any task yesterday
      final yesterdayTasks = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', currentUserId!)
          .gte('completed_at', yesterday.toIso8601String())
          .lt('completed_at', today.toIso8601String());

      // Check if user completed any task today
      final todayTasks = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', currentUserId!)
          .gte('completed_at', today.toIso8601String());

      final profile = await getUserProfile();
      if (profile == null) return;

      int currentStreak = profile['current_streak'] ?? 0;
      int newStreak = currentStreak;

      if (todayTasks.isNotEmpty) {
        // User completed task today
        if (yesterdayTasks.isNotEmpty || currentStreak == 0) {
          // Streak continues (or starts)
          newStreak = currentStreak + 1;
          print('🔥 Streak continues: $newStreak days');
        } else {
          // Missed yesterday - streak resets to 1
          newStreak = 1;
          print('⚠️ Streak broken, starting fresh: $newStreak day');
        }
      } else {
        // No task completed today yet
        if (yesterdayTasks.isEmpty && currentStreak > 0) {
          // Missed yesterday - streak broken
          newStreak = 0;
          print('💔 Streak broken: 0 days');
        } else {
          // Keep current streak (user hasn't completed today yet)
          newStreak = currentStreak;
          print('⏳ Waiting for today\'s task: $newStreak days');
        }
      }

      // Only update if streak changed
      if (newStreak != currentStreak) {
        await updateStreak(newStreak);
      }

    } catch (e) {
      print('❌ Error calculating streak: $e');
    }
  }


  Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      print('📡 Fetching all tasks from database');

      final response = await _supabase
          .from('tasks')
          .select()
          .order('category'); // Sort by category

      print('✅ Loaded ${response.length} tasks');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error loading tasks: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTasksByCategory(String category) async {
    try {
      print('📡 Fetching $category tasks');

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('category', category);

      print('✅ Loaded ${response.length} $category tasks');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error loading tasks: $e');
      return [];
    }
  }

  Future<void> completeTask({
    required String taskId,
    required int points,
  }) async {
    try {
      if (currentUserId == null) return;

      print('📡 Recording task completion');


      await _supabase.from('user_tasks').insert({
        'user_id': currentUserId,
        'task_id': taskId,
        'completed_at': DateTime.now().toIso8601String(),
      });


      await updateUserScore(points);


      await incrementTasksCompleted();

      await calculateAndUpdateStreak();

      print('✅ Task completed successfully!');
    } catch (e) {
      print('❌ Error completing task: $e');
      throw e; // Pass error up so UI can show it
    }
  }


  Future<bool> isTaskCompleted(String taskId, String taskCategory) async {
    try {
      if (currentUserId == null) return false;

      print('📡 Checking if $taskCategory task $taskId is completed');

      final now = DateTime.now();
      DateTime startDate;

      switch (taskCategory.toLowerCase()) {
        case 'daily':
        // Daily tasks reset at midnight
          startDate = DateTime(now.year, now.month, now.day);
          print('📅 Checking Daily task (resets at midnight)');
          break;

        case 'weekly':

          int daysSinceMonday = now.weekday - 1;
          startDate = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: daysSinceMonday));
          print('📅 Checking Weekly task (resets every Monday)');
          break;

        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          print('📅 Checking Monthly task (resets on 1st of month)');
          break;

        case 'one-time':

          startDate = DateTime(2000, 1, 1); // Far past date
          print('📅 Checking One-Time task (never resets)');
          break;

        default:
          startDate = DateTime(2000, 1, 1);
          print('⚠️ Unknown category: $taskCategory, treating as one-time');
          break;
      }

      // Query: Did this user complete this task after the reset date?
      final response = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', currentUserId!)
          .eq('task_id', taskId)
          .gte('completed_at', startDate.toIso8601String());

      bool completed = response.isNotEmpty;

      if (completed) {
        print('✅ Task already completed in current period');
      } else {
        print('➖ Task not completed in current period');
      }

      return completed;
    } catch (e) {
      print('❌ Error checking task: $e');
      return false;
    }
  }

  /// isTaskCompleted() instead
  /// This is kept for backward compatibility
  @Deprecated('Use isTaskCompleted(taskId, category) instead')
  Future<bool> isTaskCompletedToday(String taskId) async {
    return isTaskCompleted(taskId, 'daily');
  }


  /// Get top users by score
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      print('📡 Fetching leaderboard (top $limit)');

      final response = await _supabase
          .from('profiles')
          .select()
          .order('total_score', ascending: false) // Highest score first
          .limit(limit);

      print('✅ Loaded ${response.length} leaderboard entries');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error loading leaderboard: $e');
      return [];
    }
  }

  // ==================== GAME ====================

  Future<int> getHighScore() async {
    try {
      if (currentUserId == null) return 0;

      print('📡 Fetching high score');

      final response = await _supabase
          .from('game_scores')
          .select('score')
          .eq('user_id', currentUserId!)
          .order('score', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        print('➖ No game scores yet');
        return 0;
      }

      int highScore = response[0]['score'];
      print('✅ High score: $highScore');
      return highScore;
    } catch (e) {
      print('❌ Error loading high score: $e');
      return 0;
    }
  }

  /// Save a new game score
  Future<void> saveGameScore(int score) async {
    try {
      if (currentUserId == null) return;

      print('📡 Saving game score: $score');

      await _supabase.from('game_scores').insert({
        'user_id': currentUserId,
        'score': score,
      });

      print('✅ Game score saved!');
    } catch (e) {
      print('❌ Error saving game score: $e');
    }
  }
}