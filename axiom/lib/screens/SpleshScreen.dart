
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ProjectProvider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for UI to be ready
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final authService = context.read<AuthService>();
    final projectProvider = context.read<ProjectProvider>();

    // Try to load existing token
    await authService.loadToken();

    if (authService.token != null) {
      // User is logged in, check if there's a current project
      await projectProvider.loadProjects();

      if (projectProvider.currentProject != null) {
        // Has project, go to editor
        Navigator.pushReplacementNamed(context, '/editor');
      } else {
        // No project, go to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      // Not logged in, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.code,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Axiom',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No-Code Platform',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
