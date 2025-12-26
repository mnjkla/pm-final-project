import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Nhớ thêm vào pubspec.yaml
import 'package:latlong2/latlong.dart';      // Nhớ thêm vào pubspec.yaml
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart'; // Để gọi điện thoại
import '../core/app_colors.dart';

class TripTrackingScreen extends StatefulWidget {
  final String tripId;
  final String driverId; // ID tài xế để lấy vị trí

  const TripTrackingScreen({super.key, required this.tripId, required this.driverId});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final MapController _mapController = MapController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  LatLng _driverLocation = const LatLng(21.0285, 105.8542); // Mặc định
  Map<String, dynamic>? _driverInfo; // Thông tin tài xế
  StreamSubscription? _driverLocationSub;
  StreamSubscription? _tripStatusSub;

  @override
  void initState() {
    super.initState();
    _fetchDriverInfo();
    _listenToDriverLocation();
    _listenToTripStatus();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    _tripStatusSub?.cancel();
    super.dispose();
  }

  // 1. Lấy thông tin tài xế (Tên, Xe, SĐT...)
  void _fetchDriverInfo() async {
    // Giả sử bạn lưu info tài xế ở node 'drivers/{driverId}'
    // Nếu bạn lưu ở API backend thì gọi API ở đây
    final snapshot = await _dbRef.child('drivers/${widget.driverId}').get();
    if (snapshot.exists) {
      setState(() {
        _driverInfo = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  // 2. Lắng nghe vị trí tài xế Realtime
  void _listenToDriverLocation() {
    _driverLocationSub = _dbRef.child('drivers/${widget.driverId}').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data['lat'] != null && data['lng'] != null) {
        final newLoc = LatLng(data['lat'], data['lng']);
        setState(() {
          _driverLocation = newLoc;
        });
        _mapController.move(newLoc, 16.0); // Camera bám theo xe
      }
    });
  }

  // 3. Lắng nghe trạng thái chuyến (Để biết khi nào hoàn thành)
  void _listenToTripStatus() {
    // Bạn cần đảm bảo Backend cập nhật status vào node này hoặc dùng API
    // Ở đây demo lắng nghe Firebase nếu backend có sync status sang
  }

  void _callDriver() {
    final phone = _driverInfo?['phone'] ?? '';
    if (phone.isNotEmpty) {
      launchUrl(Uri.parse("tel:$phone"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _driverLocation, initialZoom: 16.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _driverLocation,
                    width: 50, height: 50,
                    child: const Icon(Icons.directions_car, color: AppColors.darkGreen, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // THÔNG TIN TÀI XẾ (BOTTOM SHEET)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Tài xế đang đến!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 15),

                  // Info Row
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: const NetworkImage("https://i.pravatar.cc/150?img=11"), // Demo ảnh
                      ),
                      const SizedBox(width: 15),
                      // Tên & Xe
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_driverInfo?['name'] ?? "Tài xế SmartTaxi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text("${_driverInfo?['vehicleType'] ?? 'Xe 4 chỗ'} • ${_driverInfo?['plate'] ?? '30A-123.45'}", style: const TextStyle(color: Colors.grey)),
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(" 4.9", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      // Nút Gọi
                      IconButton(
                        onPressed: _callDriver,
                        style: IconButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        icon: const Icon(Icons.phone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chi tiết chuyến (Thu gọn)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Cước phí ước tính:"),
                        Text("125.000đ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}