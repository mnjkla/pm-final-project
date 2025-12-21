import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  final AuthService _authService = AuthService();
  bool _isOnline = false; // Trạng thái nhận cuốc
  final LatLng _center = const LatLng(21.0285, 105.8542);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BẢN ĐỒ
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttaxi.driver',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.local_taxi, color: Colors.blue, size: 40), // Icon Taxi
                  ),
                ],
              ),
            ],
          ),

          // 2. THANH TRẠNG THÁI (Online/Offline)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.blue : Colors.grey[800],
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isOnline ? "ĐANG TRỰC TUYẾN" : "ĐANG NGOẠI TUYẾN",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Switch(
                    value: _isOnline,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.lightBlueAccent,
                    onChanged: (val) {
                      setState(() => _isOnline = val);
                      // TODO: Gọi API báo Backend cập nhật trạng thái
                      print("Tài xế đã chuyển sang: $val");
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. MENU DƯỚI (Thống kê & Đăng xuất)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Thu nhập", "500k", Colors.green),
                      _buildStatItem("Số cuốc", "8", Colors.orange),
                      _buildStatItem("Giờ online", "4.5h", Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        await _authService.signOut();
                        if(!mounted) return;
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}