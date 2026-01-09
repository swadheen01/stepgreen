import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool isGameStarted = false;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0; // TODO: Load from Supabase
  double basketPosition = 0.5;
  List<FallingItem> fallingItems = [];
  Timer? gameTimer;
  Timer? spawnTimer;

  final List<Map<String, dynamic>> wasteItems = [
    {'name': 'Plastic Bottle', 'icon': Icons.local_drink, 'isWaste': true, 'points': 10},
    {'name': 'Paper', 'icon': Icons.description, 'isWaste': true, 'points': 10},
    {'name': 'Can', 'icon': Icons.coffee, 'isWaste': true, 'points': 10},
    {'name': 'Battery', 'icon': Icons.battery_full, 'isWaste': true, 'points': 15},
    {'name': 'E-waste', 'icon': Icons.phone_android, 'isWaste': true, 'points': 20},
  ];

  final List<Map<String, dynamic>> goodItems = [
    {'name': 'Flower', 'icon': Icons.local_florist, 'isWaste': false},
    {'name': 'Tree', 'icon': Icons.park, 'isWaste': false},
    {'name': 'Heart', 'icon': Icons.favorite, 'isWaste': false},
  ];

  @override
  void dispose() {
    gameTimer?.cancel();
    spawnTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      isGameOver = false;
      score = 0;
      fallingItems.clear();
    });

    // Game loop - move items down
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isGameOver) {
        setState(() {
          for (var item in fallingItems) {
            item.position += 0.02;
          }

          // Check for caught items
          fallingItems.removeWhere((item) {
            if (item.position >= 0.85) {
              // Item reached basket area
              double distance = (item.horizontalPosition - basketPosition).abs();
              if (distance < 0.15) {
                // Caught the item
                if (item.isWaste) {
                  score += item.points;
                  return true;
                } else {
                  // Caught a good item - game over
                  endGame();
                  return true;
                }
              }
              return true; // Remove if missed
            }
            return false;
          });
        });
      }
    });

    // Spawn new items
    spawnTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!isGameOver) {
        spawnItem();
      }
    });
  }

  void spawnItem() {
    final random = Random();

    // 80% chance for waste, 20% chance for good item
    final isWaste = random.nextDouble() > 0.2;

    Map<String, dynamic> itemData;
    if (isWaste) {
      itemData = wasteItems[random.nextInt(wasteItems.length)];
    } else {
      itemData = goodItems[random.nextInt(goodItems.length)];
    }

    setState(() {
      fallingItems.add(FallingItem(
        icon: itemData['icon'],
        isWaste: itemData['isWaste'],
        points: itemData['points'] ?? 0,
        horizontalPosition: random.nextDouble() * 0.8 + 0.1,
        position: 0,
      ));
    });
  }

  void endGame() {
    setState(() {
      isGameOver = true;
      if (score > highScore) {
        highScore = score;
        // TODO: Save high score to Supabase
      }
    });
    gameTimer?.cancel();
    spawnTimer?.cancel();

    // Show game over dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.eco,
              color: Color(0xFF2E7D32),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Your Score: $score',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'High Score: $highScore',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              startGame();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void moveBasket(double delta) {
    setState(() {
      basketPosition = (basketPosition + delta).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text(
          'GreenStep Playground',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: !isGameStarted
          ? _buildStartScreen()
          : Stack(
        children: [
          // Score Display
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Best: $highScore',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Falling Items
          ...fallingItems.map((item) {
            return Positioned(
              top: MediaQuery.of(context).size.height * item.position,
              left: MediaQuery.of(context).size.width * item.horizontalPosition,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.isWaste
                      ? const Color(0xFF2E7D32)
                      : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          }).toList(),
          // Basket
          Positioned(
            bottom: 50,
            left: MediaQuery.of(context).size.width * basketPosition - 40,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                moveBasket(details.delta.dx / MediaQuery.of(context).size.width);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.brown,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.brown.shade800, width: 3),
                ),
                child: const Icon(
                  Icons.shopping_basket,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Drag basket to catch waste! Avoid good items!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.games,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Catch Green',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '[ Future Work ]',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'How to Play',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInstruction(
                    Icons.recycling,
                    'Catch waste items to earn points',
                    const Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(
                    Icons.close,
                    'Avoid catching good items (flowers, trees)',
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(
                    Icons.touch_app,
                    'Drag the basket left and right',
                    Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (highScore > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'High Score: $highScore',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Start Game',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class FallingItem {
  final IconData icon;
  final bool isWaste;
  final int points;
  final double horizontalPosition;
  double position;

  FallingItem({
    required this.icon,
    required this.isWaste,
    required this.points,
    required this.horizontalPosition,
    required this.position,
  });
}
