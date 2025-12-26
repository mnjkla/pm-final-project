import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart'; // Đã sửa: Import HomeScreen thay vì MainScreen
import 'driver_main_screen.dart';
import 'login_screen.dart'; // Để nút Logout có thể quay về đây

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final AuthService _authService = AuthService();

  // Controllers cho Dialog nhập thông tin
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  String _selectedVehicleType = 'CAR_4';

  // --- HÀM XỬ LÝ KHI CHỌN VAI TRÒ ---
  void _onRoleSelected(String role) async {
    // Lấy user hiện tại (đã login ở bước trước)
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Hiện Dialog nhập thông tin bổ sung
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Hoàn tất đăng ký ${role == 'DRIVER' ? 'Tài xế' : 'Khách'}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Số điện thoại *", prefixIcon: Icon(Icons.phone)),
              ),
              if (role == 'DRIVER') ...[
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  items: const [
                    DropdownMenuItem(value: 'BIKE', child: Text("Xe máy")),
                    DropdownMenuItem(value: 'CAR_4', child: Text("Ô tô 4 chỗ")),
                    DropdownMenuItem(value: 'CAR_7', child: Text("Ô tô 7 chỗ")),
                  ],
                  onChanged: (v) => _selectedVehicleType = v!,
                  decoration: const InputDecoration(labelText: "Loại xe"),
                ),
                const SizedBox(height: 15),
                TextField(controller: _brandController, decoration: const InputDecoration(labelText: "Hãng xe (VD: Honda)", prefixIcon: Icon(Icons.branding_watermark))),
                const SizedBox(height: 15),
                TextField(controller: _plateController, decoration: const InputDecoration(labelText: "Biển số", prefixIcon: Icon(Icons.confirmation_number))),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Đóng dialog, chọn lại
            child: const Text("Quay lại"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              _submitRegistration(role, user); // Gửi đi
            },
            child: const Text("Xác nhận"),
          )
        ],
      ),
    );
  }

  // --- GỬI API ĐĂNG KÝ ---
  void _submitRegistration(String role, User user) async {
    try {
      // Hiện loading (bạn có thể làm UI đẹp hơn)
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      String name = user.displayName ?? "Người dùng mới";

      await _authService.syncUserToBackend(
        role: role,
        name: name,
        phone: _phoneController.text.isEmpty ? "Chưa cập nhật" : _phoneController.text,
        vehicleType: role == 'DRIVER' ? _selectedVehicleType : null,
        vehiclePlate: role == 'DRIVER' ? _plateController.text : null,
        vehicleBrand: role == 'DRIVER' ? _brandController.text : null,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tắt loading

      // Vào màn hình chính phù hợp với vai trò
      // SỬA TẠI ĐÂY: Nếu không phải Driver thì vào HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => role == 'DRIVER' ? const DriverMainScreen() : const HomeScreen()),
            (route) => false,
      );

    } catch (e) {
      Navigator.pop(context); // Tắt loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn vai trò"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if(!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Bạn muốn tham gia với vai trò gì?", style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 40),

            // Nút Khách
            _buildBigButton(
                context,
                "KHÁCH HÀNG",
                Icons.person,
                Colors.green,
                    () => _onRoleSelected("PASSENGER")
            ),

            const SizedBox(height: 20),

            // Nút Tài xế
            _buildBigButton(
                context,
                "TÀI XẾ",
                Icons.drive_eta,
                Colors.blue,
                    () => _onRoleSelected("DRIVER")
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}