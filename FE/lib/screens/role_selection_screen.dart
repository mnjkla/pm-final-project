import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'driver_main_screen.dart';
import 'login_screen.dart'; // Đừng quên import file này

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

              // Nút Khách hàng
              _buildRoleButton(
                context,
                title: "TÔI LÀ KHÁCH HÀNG",
                subtitle: "Đặt xe và di chuyển",
                icon: Icons.person,
                color: Colors.green,
                role: "PASSENGER",
              ),

              const SizedBox(height: 20),

              // Nút Tài xế
              _buildRoleButton(
                context,
                title: "TÔI LÀ TÀI XẾ",
                subtitle: "Nhận cuốc và kiếm tiền",
                icon: Icons.drive_eta,
                color: Colors.blue,
                role: "DRIVER",
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
        required String role,
      }) {
    return InkWell(
      onTap: () {
        // Chuyển sang màn hình Đăng Nhập
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(role: role),
          ),
        );
      }, // <--- BẠN THIẾU DẤU PHẨY VÀ NGOẶC Ở ĐÂY
      child: Container( // <--- BẠN BỊ MẤT ĐOẠN UI NÀY
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