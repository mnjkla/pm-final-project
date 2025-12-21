import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Để dùng tọa độ
import '../services/auth_service.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();

  // Tọa độ mặc định (Ví dụ: Hồ Gươm, Hà Nội) - Sau này dùng Geolocator để lấy vị trí thật
  final LatLng _center = const LatLng(21.0285, 105.8542);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menu kéo từ bên trái (Drawer)
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // 1. LỚP BẢN ĐỒ (Nằm dưới cùng)
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttaxi.app',
              ),
              // Marker hiển thị vị trí của tôi
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // 2. LỚP UI: Nút Menu & Thanh tìm kiếm (Nổi bên trên)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                // Nút mở Menu
                Builder(builder: (context) {
                  return Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  );
                }),
                const SizedBox(width: 15),
                // Thanh tìm kiếm giả
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 15),
                        const Icon(Icons.search, color: Colors.green),
                        const SizedBox(width: 10),
                        Text("Bạn muốn đi đâu?", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Nút "Đặt xe ngay" ở dưới cùng
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Sẽ mở màn hình chọn điểm đến sau
                print("Mở màn hình tìm kiếm");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("ĐẶT XE NGAY", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Widget vẽ Menu bên trái
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            accountName: Text("Khách Hàng"), // Sau này lấy tên thật từ Auth
            accountEmail: Text("passenger@email.com"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.green)),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Lịch sử chuyến đi'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await _authService.signOut();
              if(!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
    );
  }
}