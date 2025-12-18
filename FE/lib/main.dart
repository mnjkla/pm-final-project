import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/role_selection_screen.dart';// Import màn hình mới

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(), // Đổi HomeScreen() thành MainScreen()
    );
  }
}