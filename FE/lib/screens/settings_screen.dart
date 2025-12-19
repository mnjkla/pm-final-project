import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'role_selection_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Header Profile
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primaryGreen.withOpacity(0.1),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=68'),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Người dùng Smart Taxi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("0909 123 456", style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Menu Items
          _buildMenuItem(Icons.person, "Thông tin cá nhân"),
          _buildMenuItem(Icons.history, "Lịch sử chuyến đi"),
          _buildMenuItem(Icons.notifications, "Thông báo"),
          _buildMenuItem(Icons.help, "Trợ giúp & Hỗ trợ"),

          const Divider(),

          // Nút Đăng xuất
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Đăng xuất", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              // Quay về màn hình chọn vai
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }
}