import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../auth/auth_service.dart';
import '../widgets/stat_card.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;
  String? errorMessage;

  // User stats for StatCards
  int userRank = 0;
  int userScore = 0;
  int totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  /// Load leaderboard data from database
  Future<void> _loadLeaderboard() async {
    try {
      print('🏆 Loading leaderboard...');

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get top users from database
      final data = await _dbService.getLeaderboard(limit: 100);

      print('✅ Loaded ${data.length} users for leaderboard');

      for (var i = 0; i < data.length; i++) {
        print('${i + 1}. ${data[i]['username']} - ${data[i]['total_score']} points');
      }

      final currentUserId = _authService.currentUserId;
      if (currentUserId != null) {
        for (var i = 0; i < data.length; i++) {
          if (data[i]['id'] == currentUserId) {
            userRank = i + 1;
            userScore = data[i]['total_score'] ?? 0;
            break;
          }
        }
      }

      setState(() {
        leaderboardData = data;
        totalUsers = data.length;
        isLoading = false;
      });

      if (data.isEmpty) {
        print('⚠️ No users found in leaderboard');
      }
    } catch (e) {
      print('❌ Error loading leaderboard: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorView()
          : leaderboardData.isEmpty
          ? _buildEmptyView()
          : _buildLeaderboardList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading leaderboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLeaderboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty view
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Rankings Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to complete tasks\nand earn points!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/tasks');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Completing Tasks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build leaderboard list
  Widget _buildLeaderboardList() {
    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: Column(
        children: [
          // Header with statistics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2E7D32),
                  const Color(0xFF4CAF50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Top Environmental Champions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${leaderboardData.length} users competing',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // User Stats - USING STATCARD WIDGET
          if (userRank > 0)
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Your Rank',
                      value: '#$userRank',
                      icon: Icons.emoji_events,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Your Score',
                      value: '$userScore',
                      icon: Icons.eco,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Total Users',
                      value: '$totalUsers',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

          // Leaderboard list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final user = leaderboardData[index];
                final rank = index + 1;
                final isTopThree = rank <= 3;
                final isCurrentUser = user['id'] == _authService.currentUserId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isTopThree ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isTopThree
                        ? BorderSide(
                      color: _getRankColor(rank),
                      width: 2,
                    )
                        : isCurrentUser
                        ? BorderSide(
                      color: const Color(0xFF2E7D32),
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                  color: isCurrentUser
                      ? const Color(0xFF2E7D32).withOpacity(0.05)
                      : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isTopThree
                                ? _getRankColor(rank).withOpacity(0.2)
                                : isCurrentUser
                                ? const Color(0xFF2E7D32).withOpacity(0.2)
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isTopThree
                                ? Text(
                              _getRankIcon(rank),
                              style: const TextStyle(fontSize: 24),
                            )
                                : Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user['username'] ?? 'Unknown User',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isTopThree
                                            ? _getRankColor(rank)
                                            : isCurrentUser
                                            ? const Color(0xFF2E7D32)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isCurrentUser) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'You',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user['tasks_completed'] ?? 0} tasks',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user['current_streak'] ?? 0} streak',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Points
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user['total_score'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Get rank color for top 3
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[400]!; // Bronze
      default:
        return Colors.grey;
    }
  }

  /// Get rank icon for top 3
  String _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}