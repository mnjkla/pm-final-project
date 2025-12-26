import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../core/api_client.dart'; // Import ApiClient
import '../core/app_colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _customerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerProfile();
  }

  Future<void> _fetchCustomerProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Gọi API: GET /api/customers/profile/{uid}
      final response = await ApiClient().dio.get('/customers/profile/$uid');
      if (response.statusCode == 200) {
        setState(() {
          _customerProfile = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi lấy profile khách: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Nếu chưa load xong API thì dùng tạm thông tin từ Firebase Auth
    String displayName = _customerProfile?['name'] ?? firebaseUser?.displayName ?? "Khách hàng thân thiết";
    String displayPhone = _customerProfile?['phone'] ?? firebaseUser?.phoneNumber ?? firebaseUser?.email ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Tài khoản"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(onPressed: (){}, child: const Text("Sửa", style: TextStyle(color: AppColors.darkGreen)))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: NetworkImage(_customerProfile?['avatarUrl'] ?? "https://i.pravatar.cc/300?img=5"),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, size: 18, color: Colors.grey[800]),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(displayPhone, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Rewards Banner (Giả lập)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.darkGreen, Colors.greenAccent]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(Icons.diamond, color: Colors.white, size: 30),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Thành viên Vàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("0 điểm tích lũy", style: TextStyle(color: Colors.white70)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu List
            _buildMenuItem(Icons.history, "Lịch sử chuyến đi", () {}),
            _buildMenuItem(Icons.location_on_outlined, "Địa điểm đã lưu", () {}),
            _buildMenuItem(Icons.payment, "Thanh toán", () {}),
            _buildMenuItem(Icons.notifications_none, "Thông báo", () {}),
            _buildMenuItem(Icons.settings_outlined, "Cài đặt", () {}),

            const SizedBox(height: 20),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 15)
                ),
                onPressed: () async {
                  await AuthService().signOut();
                  if(mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false
                    );
                  }
                },
                child: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}