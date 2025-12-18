import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Bản đồ
import 'package:latlong2/latlong.dart';      // Tọa độ
import 'package:geolocator/geolocator.dart'; // Lấy vị trí GPS
import '../core/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tọa độ mặc định (TP.HCM) nếu chưa lấy được GPS
  LatLng _currentLocation = const LatLng(10.7769, 106.7009);
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Gọi hàm lấy vị trí ngay khi màn hình mở
  }

  // Hàm xin quyền và lấy tọa độ GPS
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Kiểm tra GPS có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Nếu tắt, dùng tọa độ mặc định
      setState(() => _isLoading = false);
      return;
    }

    // 2. Xin quyền truy cập
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    // 3. Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    // Di chuyển camera bản đồ tới vị trí vừa lấy
    _mapController.move(_currentLocation, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // --- LỚP 1: BẢN ĐỒ (Nằm dưới cùng) ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation, // Bắt đầu tại đây
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttaxi.app',
              ),
              // Marker hiển thị "Tôi đang ở đây"
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_history, // Icon người dùng
                      color: Colors.blueAccent,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // --- LỚP 2: GIAO DIỆN NGƯỜI DÙNG (Đè lên trên) ---

          // Header & Avatar (Đã sửa lại cho gọn để nhìn thấy bản đồ)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                  ),
                  child: const Icon(Icons.menu, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?q=80&w=200&auto=format&fit=crop',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar (Khung chọn điểm đến)
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: AppColors.primaryGreen, size: 28),
                  SizedBox(width: 15),
                  Text(
                    "Bạn muốn đi đâu?",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service Buttons (Nút chọn xe - Đặt ở dưới cùng)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(blurRadius: 15, color: Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Chọn phương tiện", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildServiceButton(Icons.two_wheeler, "Bike", true),
                      _buildServiceButton(Icons.directions_car, "Car", false),
                      _buildServiceButton(Icons.local_shipping, "Ship", false),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading Indicator (Khi đang tìm GPS)
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  // Widget con: Nút dịch vụ
  Widget _buildServiceButton(IconData icon, String label, bool isSelected) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.grey[100],
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.4), blurRadius: 10, offset: const Offset(0,5))]
                : [],
          ),
          child: Icon(
            icon,
            size: 35,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        )),
      ],
    );
  }
}