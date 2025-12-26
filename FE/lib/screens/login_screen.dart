import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Bắt buộc thêm dòng này để bắt lỗi FirebaseAuthException
import '../services/auth_service.dart';
import 'home_screen.dart';        // Màn hình Khách
import 'driver_main_screen.dart'; // Màn hình Tài xế
import 'role_selection_screen.dart'; // Màn hình chọn vai trò (cho user mới)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Biến cho chế độ Email/Pass
  bool _isLoginMode = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // final TextEditingController _nameController = TextEditingController(); // Tạm không dùng ở màn hình này

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    // _nameController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ: PHÂN QUYỀN SAU KHI ĐĂNG NHẬP ---
  Future<void> _handlePostLogin() async {
    if (!mounted) return;
    // Vẫn giữ loading để người dùng đợi kiểm tra Role
    setState(() => _isLoading = true);

    try {
      // 1. Hỏi Backend: "Tôi là ai?"
      final profile = await _authService.fetchUserProfile(); //
      final String role = profile['role']; // DRIVER, PASSENGER, hoặc NEW

      if (!mounted) return;

      // 2. Điều hướng dựa trên câu trả lời
      if (role == 'DRIVER') {
        print("Xin chào Tài xế!");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverMainScreen()));
      } else if (role == 'PASSENGER') {
        print("Xin chào Khách hàng!");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        // role == 'NEW' -> Chưa có trong DB -> Sang màn chọn vai trò để đăng ký
        print("Người dùng mới -> Chuyển sang chọn vai trò");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
      }

    } catch (e) {
      // Nếu lỗi fetch profile, có thể do chưa sync -> coi là NEW hoặc báo lỗi
      print("Lỗi lấy hồ sơ: $e");
      // Trường hợp này thường xảy ra khi user mới đăng ký bằng Email nhưng chưa kịp sync
      // Chúng ta sẽ đẩy sang RoleSelectionScreen để họ làm lại quy trình sync
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Xử lý Google ---
  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle(); //
      if (user != null) {
        await _handlePostLogin(); // Đăng nhập xong -> Gọi hàm phân quyền
      } else {
        setState(() => _isLoading = false); // User hủy chọn Google
      }
    } catch (e) {
      _showError("Lỗi Google: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- Xử lý Email/Pass (Đã cập nhật xử lý lỗi chi tiết) ---
  void _handleEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        // Đăng nhập
        await _authService.signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim()
        ); //

        await _handlePostLogin();
      } else {
        // Đăng ký tài khoản Firebase trước
        await _authService.signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim()
        ); //

        // Đăng ký thành công -> Chuyển sang màn hình chọn vai trò
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
        }
      }
    } on FirebaseAuthException catch (e) {
      // Bắt riêng lỗi Firebase để hiển thị tiếng Việt rõ ràng
      String msg = "Lỗi xác thực";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = "Tài khoản không tồn tại hoặc sai mật khẩu.";
      } else if (e.code == 'wrong-password') {
        msg = "Sai mật khẩu.";
      } else if (e.code == 'email-already-in-use') {
        msg = "Email này đã được đăng ký rồi.";
      } else if (e.code == 'invalid-email') {
        msg = "Định dạng email không hợp lệ.";
      } else if (e.code == 'weak-password') {
        msg = "Mật khẩu quá yếu (cần ít nhất 6 ký tự).";
      }
      _showError(msg);
      setState(() => _isLoading = false);
    } catch (e) {
      _showError("Lỗi không xác định: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_taxi, size: 80, color: Colors.green),
              const SizedBox(height: 10),
              const Text("SMART TAXI", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 40),

              // Form Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 15),

              // Form Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder()
                ),
              ),
              const SizedBox(height: 25),

              // Nút Login/Register
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                      _isLoginMode ? "ĐĂNG NHẬP" : "ĐĂNG KÝ NGAY",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),

              // Chuyển chế độ
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(_isLoginMode ? "Chưa có tài khoản? Đăng ký" : "Đã có tài khoản? Đăng nhập"),
              ),

              const Divider(height: 40),

              // Nút Google
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
                  label: const Text("Tiếp tục bằng Google", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}