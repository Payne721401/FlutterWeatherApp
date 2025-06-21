import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to home screen after a delay
    Future.delayed(const Duration(seconds: 3), () {
      // *** FIX: Check if the widget is still mounted before using context ***
      if (!mounted) return; 
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Splash Screen UI (Modern, simple, app name, theme image)
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for theme image/logo
            Icon(Icons.wb_sunny, size: 100, color: Colors.amber),
            SizedBox(height: 20),
            Text(
              '台灣天氣通',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '你的AI天氣助手',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
