import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(user?.email ?? "Khách hàng", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.phoneNumber ?? "", style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            // Menu Items
            _buildProfileItem(Icons.star_outline, "Đánh giá của tôi", () {}),
            _buildProfileItem(Icons.discount_outlined, "Ưu đãi / Mã giảm giá", () {}),
            _buildProfileItem(Icons.help_outline, "Hỗ trợ", () {}),
            _buildProfileItem(Icons.settings_outlined, "Cài đặt", () {}),

            const Divider(height: 30),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}