import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Import đúng đường dẫn

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Taxi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Sau này có thể cấu hình Theme ở folder core/theme.dart
      ),
      home: const HomeScreen(),
    );
  }
}