import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';       // Màn hình Khách
import 'driver_main_screen.dart'; // Màn hình Tài xế

class LoginScreen extends StatefulWidget {
  final String role; // "PASSENGER" hoặc "DRIVER"

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Khởi tạo AuthService (Đảm bảo bạn đã tạo file này như hướng dẫn trước)
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      // 1. Đăng nhập Firebase
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // 2. Lấy tên user
        String name = userCredential.user?.displayName ?? "Người dùng mới";

        // 3. Gọi Backend để lưu user vào MongoDB
        await _authService.syncUserToBackend(widget.role, name);

        // 4. Chuyển màn hình
        if (!mounted) return;

        // Xóa hết các màn hình cũ trong stack để không back lại được Login
        Navigator.popUntil(context, (route) => route.isFirst);

        if (widget.role == 'PASSENGER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverMainScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi đăng nhập: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.role == 'DRIVER';
    final mainColor = isDriver ? Colors.blue : Colors.green;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: mainColor), // Nút back màu theo role
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon đại diện
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDriver ? Icons.drive_eta : Icons.person,
                size: 60,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 30),

            Text(
              "Đăng nhập ${isDriver ? 'Tài xế' : 'Khách hàng'}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Vui lòng đăng nhập để đồng bộ thông tin chuyến đi của bạn.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 50),

            // Nút Login Google
            _isLoading
                ? CircularProgressIndicator(color: mainColor)
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleGoogleLogin,
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  "Tiếp tục với Google",
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}