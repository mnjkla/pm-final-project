import 'package:flutter/material.dart';
import '../core/app_colors.dart'; // Đảm bảo file này có màu sắc (nếu chưa có thì dùng Colors.green)
import 'main_screen.dart'; // Màn hình Khách hàng (Chứa HomeScreen)
import 'driver_home_screen.dart'; // Màn hình Tài xế
import 'driver_main_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo hoặc Tiêu đề
              const Icon(Icons.local_taxi, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                "SMART TAXI",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Bạn muốn sử dụng với vai trò gì?",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // --- NÚT CHỌN KHÁCH HÀNG ---
              _buildRoleButton(
                context,
                title: "TÔI LÀ KHÁCH HÀNG",
                subtitle: "Đặt xe và di chuyển",
                icon: Icons.person,
                color: Colors.green,
                destination: const MainScreen(),
              ),

              const SizedBox(height: 20),

              // --- NÚT CHỌN TÀI XẾ ---
              _buildRoleButton(
                context,
                title: "TÔI LÀ TÀI XẾ",
                subtitle: "Nhận cuốc và kiếm tiền",
                icon: Icons.drive_eta,
                color: Colors.blue,
                destination: const DriverMainScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Widget destination,
      }) {
    return InkWell(
      onTap: () {
        // Điều hướng sang màn hình tương ứng
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }
}