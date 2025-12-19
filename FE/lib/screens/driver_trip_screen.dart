import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_colors.dart';

class DriverTripScreen extends StatefulWidget {
  const DriverTripScreen({super.key});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  // Trạng thái chuyến đi: 0=Đang đến, 1=Đã đến điểm đón, 2=Đang chở khách, 3=Hoàn thành
  int _tripStep = 0;
  String _buttonText = "ĐÃ ĐẾN ĐIỂM ĐÓN";
  Color _buttonColor = Colors.orange;

  void _nextStep() {
    setState(() {
      if (_tripStep == 0) {
        _tripStep = 1;
        _buttonText = "BẮT ĐẦU CHUYẾN ĐI";
        _buttonColor = Colors.blue;
      } else if (_tripStep == 1) {
        _tripStep = 2;
        _buttonText = "HOÀN THÀNH CHUYẾN";
        _buttonColor = Colors.red;
      } else if (_tripStep == 2) {
        // Kết thúc
        Navigator.pop(context); // Quay về màn hình chờ
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bản đồ dẫn đường
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(10.7769, 106.7009), // HCM
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              // MarkerLayer... (Thêm Marker của Khách và Điểm đến)
            ],
          ),

          // Info Panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thông tin khách
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: const Text("Khách hàng: Anh Minh", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Thu tiền mặt: 45.000đ"),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () {},
                    ),
                  ),
                  const Divider(),

                  // Địa chỉ
                  Row(
                    children: [
                      Icon(Icons.my_location, color: _tripStep < 2 ? Colors.blue : Colors.grey),
                      const SizedBox(width: 10),
                      const Expanded(child: Text("123 Lê Lợi, Q.1 (Điểm đón)", style: TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: _tripStep >= 2 ? Colors.red : Colors.grey),
                      const SizedBox(width: 10),
                      const Expanded(child: Text("Chợ Bến Thành (Điểm đến)", style: TextStyle(fontWeight: FontWeight.w500))),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Nút Trạng thái (To đùng)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(backgroundColor: _buttonColor),
                      child: Text(_buttonText, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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