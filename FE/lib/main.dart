import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
// 1. THÊM DÒNG NÀY (File này do lệnh flutterfire configure tạo ra)
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/role_selection_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. SỬA ĐOẠN NÀY:
  // Truyền options vào để Web biết cấu hình Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ... theme
      // Sửa home thành LoginScreen (không cần tham số)
      home: const RoleSelectionScreen(),
    );
  }
}