import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final int points;
  final String category;
  final IconData icon;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.category,
    required this.icon,
  });
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  String selectedCategory = 'All';

  // TODO: This data will come from Supabase later
  final List<Task> allTasks = [
    // Daily Tasks
    Task(
      id: '1',
      title: 'Use Reusable Water Bottle',
      description: 'Avoid buying plastic bottled water',
      points: 10,
      category: 'Daily',
      icon: Icons.water_drop,
    ),
    Task(
      id: '2',
      title: 'Turn Off Lights',
      description: 'Switch off lights when leaving a room',
      points: 10,
      category: 'Daily',
      icon: Icons.lightbulb_outline,
    ),
    Task(
      id: '3',
      title: 'Use Reusable Shopping Bag',
      description: 'Bring your own bag while shopping',
      points: 15,
      category: 'Daily',
      icon: Icons.shopping_bag,
    ),
    Task(
      id: '4',
      title: 'Avoid Single-Use Plastic',
      description: 'Say no to plastic straws and utensils',
      points: 15,
      category: 'Daily',
      icon: Icons.no_drinks,
    ),
    Task(
      id: '5',
      title: 'Use Public Transport',
      description: 'Take bus or train instead of private car',
      points: 20,
      category: 'Daily',
      icon: Icons.directions_bus,
    ),
    Task(
      id: '6',
      title: 'Unplug Electronics',
      description: 'Unplug devices when not in use',
      points: 10,
      category: 'Daily',
      icon: Icons.power_off,
    ),
    // Weekly Tasks
    Task(
      id: '7',
      title: 'Plant a Tree',
      description: 'Plant a tree or seedling',
      points: 50,
      category: 'Weekly',
      icon: Icons.park,
    ),
    Task(
      id: '8',
      title: 'Organize Recycling',
      description: 'Collect and recycle waste materials',
      points: 40,
      category: 'Weekly',
      icon: Icons.recycling,
    ),
    Task(
      id: '9',
      title: 'Clean Public Area',
      description: 'Pick up litter in your neighborhood',
      points: 35,
      category: 'Weekly',
      icon: Icons.cleaning_services,
    ),
    Task(
      id: '10',
      title: 'Compost Food Waste',
      description: 'Start or maintain a compost bin',
      points: 30,
      category: 'Weekly',
      icon: Icons.compost,
    ),
    Task(
      id: '11',
      title: 'Donate Old Clothes',
      description: 'Give away clothes instead of throwing them',
      points: 30,
      category: 'Weekly',
      icon: Icons.checkroom,
    ),
    // One-Time Tasks
    Task(
      id: '12',
      title: 'Switch to Eco Products',
      description: 'Use biodegradable cleaning products',
      points: 60,
      category: 'One-Time',
      icon: Icons.eco,
    ),
    Task(
      id: '13',
      title: 'Install LED Bulbs',
      description: 'Replace old bulbs with LED ones',
      points: 50,
      category: 'One-Time',
      icon: Icons.lightbulb,
    ),
    Task(
      id: '14',
      title: 'Create Home Garden',
      description: 'Start growing vegetables at home',
      points: 70,
      category: 'One-Time',
      icon: Icons.yard,
    ),
    Task(
      id: '15',
      title: 'Rainwater Harvesting',
      description: 'Set up a rainwater collection system',
      points: 100,
      category: 'One-Time',
      icon: Icons.water,
    ),
  ];

  List<Task> get filteredTasks {
    if (selectedCategory == 'All') {
      return allTasks;
    }
    return allTasks.where((task) => task.category == selectedCategory).toList();
  }

  void _completeTask(Task task) {
    // TODO: Save to Supabase and update user score
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.amber),
            const SizedBox(width: 10),
            const Text('Task Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You earned ${task.points} points!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Available Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Daily'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Weekly'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('One-Time'),
                ],
              ),
            ),
          ),
          // Task List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _buildTaskCard(task);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategory == category;
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedCategory = category;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2E7D32),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    Color categoryColor;
    switch (task.category) {
      case 'Daily':
        categoryColor = Colors.blue;
        break;
      case 'Weekly':
        categoryColor = Colors.orange;
        break;
      case 'One-Time':
        categoryColor = Colors.purple;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                task.icon,
                color: const Color(0xFF2E7D32),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Task Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.points} pts',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Complete Button
            IconButton(
              onPressed: () => _completeTask(task),
              icon: const Icon(Icons.check_circle_outline),
              color: const Color(0xFF2E7D32),
              iconSize: 32,
            ),
          ],
        ),
      ),
    );
  }
}