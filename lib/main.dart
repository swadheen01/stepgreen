import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_gate.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
import 'pages/task_list_page.dart';
import 'pages/profile_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/game_page.dart';

void main() async{
  await Supabase.initialize(url: "https://klwciguxetuwsgygouam.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtsd2NpZ3V4ZXR1d3NneWdvdWFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU3NDIwMjEsImV4cCI6MjA4MTMxODAyMX0.APVHqH6OLoDRoQT2cEa6A01TwEG3UVD6hAw_0D6S0wE"
  );
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
      // Start with AuthGate (it decides: login or home?)
      home: const SplashScreen(),
      // Define routes for navigation
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login':(context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/tasks': (context) => const TaskListPage(),
        '/profile': (context) => const ProfilePage(),
        '/leaderboard': (context) => const LeaderboardPage(),
        '/game': (context) => const GamePage(),
      },
    );
  }
}