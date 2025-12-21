import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // TODO: This data will come from Supabase
  final List<Map<String, dynamic>> leaderboardData = [
    {
      'rank': 1,
      'name': 'Anika Rahman',
      'score': 1250,
      'tasks': 87,
    },
    {
      'rank': 2,
      'name': 'Fahim Ahmed',
      'score': 980,
      'tasks': 65,
    },
    {
      'rank': 3,
      'name': 'Nusrat Jahan',
      'score': 850,
      'tasks': 56,
    },
    {
      'rank': 4,
      'name': 'Swadheen Islam Robi',
      'score': 450,
      'tasks': 23,
      'isCurrentUser': true,
    },
    {
      'rank': 5,
      'name': 'Tanzim Hossain',
      'score': 420,
      'tasks': 21,
    },
    {
      'rank': 6,
      'name': 'Mehedi Hassan',
      'score': 380,
      'tasks': 19,
    },
    {
      'rank': 7,
      'name': 'Rifa Tabassum',
      'score': 340,
      'tasks': 18,
    },
    {
      'rank': 8,
      'name': 'Sakib Khan',
      'score': 290,
      'tasks': 15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Top 3 Winners Podium
          Container(
            padding: const EdgeInsets.all(20),
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
                const Text(
                  'Top Eco Warriors',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2nd Place
                    _buildPodium(
                      leaderboardData[1],
                      2,
                      100,
                      Colors.grey[400]!,
                    ),
                    const SizedBox(width: 12),
                    // 1st Place
                    _buildPodium(
                      leaderboardData[0],
                      1,
                      130,
                      Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    // 3rd Place
                    _buildPodium(
                      leaderboardData[2],
                      3,
                      80,
                      Colors.brown[300]!,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Rest of Leaderboard
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: leaderboardData.length - 3,
              itemBuilder: (context, index) {
                final userData = leaderboardData[index + 3];
                return _buildLeaderboardItem(userData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(
      Map<String, dynamic> user, int rank, double height, Color color) {
    IconData icon;
    if (rank == 1) {
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      icon = Icons.military_tech;
    } else {
      icon = Icons.workspace_premium;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: rank == 1 ? 32 : 24,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            user['name'].split(' ')[0],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${user['score']} pts',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: Colors.white,
                fontSize: rank == 1 ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user) {
    final bool isCurrentUser = user['isCurrentUser'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF2E7D32).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF2E7D32), width: 2)
            : null,
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
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? const Color(0xFF2E7D32)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#${user['rank']}',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Profile Picture
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser
                              ? const Color(0xFF2E7D32)
                              : Colors.black,
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
                Text(
                  '${user['tasks']} tasks completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.eco,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user['score']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const Text(
                'points',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}