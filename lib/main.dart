import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
import 'pages/task_list_page.dart';
import 'pages/profile_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/game_page.dart';

void main() {
  runApp(const GreenStepApp());
}

class GreenStepApp extends StatelessWidget {
  const GreenStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenStep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/tasks': (context) => const TaskListPage(),
        '/profile': (context) => const ProfilePage(),
        '/leaderboard': (context) => const LeaderboardPage(),
        '/game': (context) => const GamePage(),
      },
    );
  }
}