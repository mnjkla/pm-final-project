import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase
import '../core/app_colors.dart';
import '../models/trip_model.dart';

class TripTrackingScreen extends StatefulWidget {
  final Trip trip;
  const TripTrackingScreen({super.key, required this.trip});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng _driverLocation = const LatLng(10.7769, 106.7009); // Vị trí mặc định
  double _driverAngle = 0.0;

  // Lấy ID tài xế từ Trip (hoặc hardcode TX_01 để test nếu chưa có logic gán driver)
  late final String _driverId;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    // Trong thực tế: _driverId = widget.trip.driverId!;
    _driverId = "TX_01"; // Hardcode để test với máy tài xế
    _listenToDriverLocation();
  }

  void _listenToDriverLocation() {
    // Lắng nghe thay đổi tại node 'drivers/TX_01'
    _dbRef.child('drivers/$_driverId').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _driverLocation = LatLng(data['lat'], data['lng']);
          _driverAngle = (data['angle'] ?? 0.0) * 1.0; // Lấy hướng xe
        });

        // Tự động di chuyển camera theo xe (tuỳ chọn)
        _mapController.move(_driverLocation, 16.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _driverLocation, initialZoom: 16.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                markers: [
                  // MARKER TÀI XẾ (Di chuyển mượt mà)
                  Marker(
                    point: _driverLocation,
                    width: 60, height: 60,
                    // Xoay icon theo hướng xe chạy
                    child: Transform.rotate(
                      angle: _driverAngle * (3.14159 / 180), // Đổi độ sang radian
                      child: const Icon(Icons.directions_car, color: AppColors.primaryGreen, size: 40),
                    ),
                  ),
                  // Marker khách (Tĩnh)
                  Marker(
                    point: const LatLng(10.7800, 106.7050), // Vị trí đón
                    width: 50, height: 50,
                    child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // ... (Phần Bottom Sheet thông tin tài xế giữ nguyên như cũ) ...
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: const Text("Đang kết nối vệ tinh...", textAlign: TextAlign.center),
            ),
          )
        ],
      ),
    );
  }
}