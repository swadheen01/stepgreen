import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();

  late TabController _tabController;

  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> dailyTasks = [];
  List<Map<String, dynamic>> weeklyTasks = [];
  List<Map<String, dynamic>> monthlyTasks = [];
  List<Map<String, dynamic>> oneTimeTasks = [];

  Map<String, bool> completedTasks = {};
  String? completingTaskId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load all tasks and organize by category
  Future<void> _loadTasks() async {
    try {
      print('📡 Loading all tasks...');

      setState(() {
        isLoading = true;
      });

      final tasks = await _dbService.getAllTasks();
      print('✅ Loaded ${tasks.length} tasks from database');

      List<Map<String, dynamic>> daily = [];
      List<Map<String, dynamic>> weekly = [];
      List<Map<String, dynamic>> monthly = [];
      List<Map<String, dynamic>> oneTime = [];

      for (var task in tasks) {
        String category = (task['category'] ?? 'Daily').toString().toLowerCase();

        if (category.contains('daily')) {
          daily.add(task);
        } else if (category.contains('weekly')) {
          weekly.add(task);
        } else if (category.contains('monthly')) {
          monthly.add(task);
        } else if (category.contains('one-time') || category.contains('onetime')) {
          oneTime.add(task);
        } else {
          daily.add(task);
        }
      }

      print('📊 Daily: ${daily.length}, Weekly: ${weekly.length}, Monthly: ${monthly.length}, One-Time: ${oneTime.length}');

      Map<String, bool> completed = {};
      for (var task in tasks) {
        final taskCategory = task['category'] ?? 'Daily';
        final isCompleted = await _dbService.isTaskCompleted(
          task['id'],
          taskCategory, // ← Pass the category to check correct reset period
        );
        completed[task['id']] = isCompleted;
      }

      setState(() {
        allTasks = tasks;
        dailyTasks = daily;
        weeklyTasks = weekly;
        monthlyTasks = monthly;
        oneTimeTasks = oneTime;
        completedTasks = completed;
        isLoading = false;
      });

      print('✅ Task loading complete!');
    } catch (e) {
      print('❌ Error loading tasks: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle task completion
  Future<void> _handleCompleteTask(Map<String, dynamic> task) async {
    print('🔘 Complete button clicked for: ${task['title']}');
    print('🔘 Task ID: ${task['id']}');
    print('🔘 Category: ${task['category']}');
    print('🔘 Points: ${task['points']}');

    // ✅ UPDATED: Check if task is already completed in current period
    final taskCategory = task['category'] ?? 'Daily';
    final alreadyCompleted = await _dbService.isTaskCompleted(
      task['id'],
      taskCategory,
    );

    if (alreadyCompleted) {
      print('⚠️ Task already completed in current period');

      // Show category-specific message
      String message = _getCompletionMessage(taskCategory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      completingTaskId = task['id'];
    });

    try {
      print('📡 Calling completeTask in database service...');

      await _dbService.completeTask(
        taskId: task['id'],
        points: task['points'],
      );

      print('✅ Task completed in database!');

      setState(() {
        completedTasks[task['id']] = true;
        completingTaskId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('✅ +${task['points']} points earned!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('✅ Success message shown!');
    } catch (e) {
      print('❌ ERROR completing task: $e');

      setState(() {
        completingTaskId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getCompletionMessage(String category) {
    switch (category.toLowerCase()) {
      case 'daily':
        return 'Already completed today! Come back tomorrow at midnight.';
      case 'weekly':
        return 'Already completed this week! Come back next Monday.';
      case 'monthly':
        return 'Already completed this month! Come back on the 1st.';
      case 'one-time':
      case 'onetime':
        return 'This task is already completed permanently!';
      default:
        return 'This task is already completed!';
    }
  }

  String _getButtonText(String category, bool isCompleted) {
    if (!isCompleted) {
      return 'Complete Task';
    }

    switch (category.toLowerCase()) {
      case 'daily':
        return 'Completed Today';
      case 'weekly':
        return 'Completed This Week';
      case 'monthly':
        return 'Completed This Month';
      case 'one-time':
      case 'onetime':
        return 'Completed Forever';
      default:
        return 'Completed';
    }
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks in this category',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final taskId = task['id'];
          final taskCategory = task['category'] ?? 'Daily';
          final isCompleted = completedTasks[taskId] ?? false;
          final isProcessing = completingTaskId == taskId;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task header
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            task['icon'] ?? '🌱',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title and category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] ?? 'Untitled Task',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? Colors.grey
                                    : Colors.black87,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(taskCategory),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    taskCategory,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${task['points'] ?? 0} points',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (task['description'] != null &&
                      task['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      task['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Complete button with dynamic text
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isCompleted || isProcessing
                          ? null
                          : () => _handleCompleteTask(task),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted
                            ? Colors.grey[300]
                            : const Color(0xFF2E7D32),
                        foregroundColor:
                        isCompleted ? Colors.grey[600] : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: isCompleted ? 0 : 2,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getButtonText(taskCategory, isCompleted),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Tasks'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.all_inclusive, size: 20),
                  const SizedBox(width: 8),
                  Text('All (${allTasks.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.today, size: 20),
                  const SizedBox(width: 8),
                  Text('Daily (${dailyTasks.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 20),
                  const SizedBox(width: 8),
                  Text('Weekly (${weeklyTasks.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 20),
                  const SizedBox(width: 8),
                  Text('Monthly (${monthlyTasks.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.star, size: 20),
                  const SizedBox(width: 8),
                  Text('One-Time (${oneTimeTasks.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(allTasks),
          _buildTaskList(dailyTasks),
          _buildTaskList(weeklyTasks),
          _buildTaskList(monthlyTasks),
          _buildTaskList(oneTimeTasks),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'daily':
        return Colors.blue;
      case 'weekly':
        return Colors.orange;
      case 'monthly':
        return Colors.purple;
      case 'one-time':
      case 'onetime':
        return Colors.pink;
      default:
        return Colors.green;
    }
  }
}