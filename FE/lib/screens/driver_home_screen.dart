import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/app_colors.dart'; // Đảm bảo có file này

// Giả lập Model chuyến đi
class TripRequest {
  final String pickupAddress;
  final String destAddress;
  final LatLng destLocation; // Thêm tọa độ điểm đến để tính toán
  final double distance;
  final double price;

  TripRequest({
    required this.pickupAddress,
    required this.destAddress,
    required this.destLocation,
    required this.distance,
    required this.price,
  });
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final MapController _mapController = MapController();

  // Trạng thái tài xế
  bool _isOnline = false;
  bool _isInTrip = false;
  LatLng? _currentPosition;

  // --- TÍNH NĂNG MỚI: BỘ LỌC ĐIỂM ĐẾN ---
  bool _isDestinationFilterOn = false;
  LatLng? _preferredDestination; // Vị trí tài xế muốn đến
  String _preferredAddress = "";   // Tên địa chỉ muốn đến

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  void _toggleOnline(bool value) {
    setState(() {
      _isOnline = value;
    });

    if (_isOnline) {
      String msg = "Bạn đang TRỰC TUYẾN.";
      if (_isDestinationFilterOn) msg += " (Chế độ tiện đường)";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bạn đã NGOẠI TUYẾN."), backgroundColor: Colors.grey));
    }
  }

  // --- HÀM CÀI ĐẶT ĐIỂM ĐẾN ---
  void _setDestinationFilter() {
    // Demo: Chọn nhanh 2 vị trí (Thực tế sẽ mở bản đồ chọn như bên App Khách)
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chọn khu vực muốn chạy đến:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.blue),
                title: const Text("Nhà riêng (Thủ Đức)"),
                subtitle: const Text("Ưu tiên cuốc về hướng Thủ Đức"),
                onTap: () {
                  setState(() {
                    _isDestinationFilterOn = true;
                    _preferredDestination = const LatLng(10.8499, 106.7716); // Thủ Đức
                    _preferredAddress = "Thủ Đức";
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.airplanemode_active, color: Colors.red),
                title: const Text("Sân bay Tân Sơn Nhất"),
                subtitle: const Text("Ưu tiên cuốc ra sân bay"),
                onTap: () {
                  setState(() {
                    _isDestinationFilterOn = true;
                    _preferredDestination = const LatLng(10.8185, 106.6588); // Sân bay
                    _preferredAddress = "Sân bay TSN";
                  });
                  Navigator.pop(context);
                },
              ),
              if (_isDestinationFilterOn)
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.grey),
                  title: const Text("Tắt bộ lọc (Nhận mọi cuốc)"),
                  onTap: () {
                    setState(() {
                      _isDestinationFilterOn = false;
                      _preferredDestination = null;
                      _preferredAddress = "";
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- GIẢ LẬP CÓ KHÁCH ---
  void _simulateIncomingRequest() {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng bật Trực tuyến trước!")));
      return;
    }

    // 1. Tạo một chuyến đi giả (Hướng về Sân bay)
    final request = TripRequest(
      pickupAddress: "123 Nguyễn Huệ, Quận 1",
      destAddress: "Ga Quốc tế, Sân bay TSN",
      destLocation: const LatLng(10.8185, 106.6588), // Tọa độ sân bay
      distance: 8.5,
      price: 120000,
    );

    // 2. LOGIC LỌC: Kiểm tra nếu đang bật lọc
    if (_isDestinationFilterOn && _preferredDestination != null) {
      // Tính khoảng cách từ Điểm Trả Khách -> Điểm Tài Xế Muốn Đến
      final Distance distanceCalculator = const Distance();
      double dist = distanceCalculator.as(LengthUnit.Kilometer, request.destLocation, _preferredDestination!);

      // Nếu điểm trả khách cách điểm muốn đến quá 3km -> Không nổ cuốc này
      if (dist > 3.0) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã bỏ qua 1 cuốc do ngược đường (Cách $_preferredAddress ${dist.toStringAsFixed(1)}km)"),
              duration: const Duration(seconds: 2),
            )
        );
        return;
      }
    }

    _showIncomingRequestDialog(request);
  }

  void _showIncomingRequestDialog(TripRequest request) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Tiện đường
              if (_isDestinationFilterOn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.deepOrange),
                      const SizedBox(width: 5),
                      Text("TIỆN ĐƯỜNG VỀ $_preferredAddress", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),

              const Text("CHUYẾN XE MỚI!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 5),
              Text("${(request.distance).toStringAsFixed(1)} km - ${(request.price/1000).toStringAsFixed(0)}k VND", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(height: 30),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: const Text("Đón tại:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(request.pickupAddress, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on, color: Colors.red),
                title: const Text("Đến:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(request.destAddress, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("BỎ QUA", style: TextStyle(color: Colors.grey)))),
                  const SizedBox(width: 15),
                  Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); setState(() => _isInTrip = true); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("NHẬN CUỐC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isInTrip ? "Đang chở khách" : (_isOnline ? "Trực tuyến" : "Ngoại tuyến")),
        backgroundColor: _isInTrip ? Colors.blue : (_isOnline ? Colors.green : Colors.grey),
        foregroundColor: Colors.white,
        actions: [
          if (_isOnline && !_isInTrip)
            IconButton(icon: const Icon(Icons.notifications_active), onPressed: _simulateIncomingRequest)
        ],
      ),
      body: Stack(
        children: [
          // 1. MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(10.762622, 106.660172),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttaxi.driver',
              ),
              // Marker Vị trí tài xế
              if (_currentPosition != null)
                MarkerLayer(markers: [Marker(point: _currentPosition!, width: 50, height: 50, child: const Icon(Icons.directions_car, color: Colors.blueAccent, size: 40))]),

              // Marker Điểm đến ưu tiên (Nếu đang bật)
              if (_isDestinationFilterOn && _preferredDestination != null)
                MarkerLayer(markers: [Marker(point: _preferredDestination!, width: 50, height: 50, child: const Icon(Icons.flag, color: Colors.orange, size: 40))]),
            ],
          ),

          // 2. BANNER THÔNG BÁO CHẾ ĐỘ LỌC (Nằm trên cùng)
          if (_isDestinationFilterOn && _isOnline && !_isInTrip)
            Positioned(
              top: 10, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(30), boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.alt_route, color: Colors.white),
                    const SizedBox(width: 8),
                    Text("Đang tìm khách về hướng $_preferredAddress", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // 3. CONTROL PANEL
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: _isInTrip ? _buildInTripUI() : _buildOnlineToggleUI(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOnlineToggleUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isOnline ? "Sẵn sàng" : "Bạn đang nghỉ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_isOnline ? "Đang chờ cuốc..." : "Bật lên để kiếm tiền", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            Transform.scale(scale: 1.2, child: Switch(value: _isOnline, activeColor: Colors.green, onChanged: _toggleOnline)),
          ],
        ),

        // --- NÚT BỘ LỌC ĐIỂM ĐẾN ---
        if (!_isOnline) // Chỉ cho cài đặt khi đang Ngoại tuyến (hoặc tuỳ logic)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: InkWell(
              onTap: _setDestinationFilter,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _isDestinationFilterOn ? Colors.orange[50] : Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: _isDestinationFilterOn ? Colors.orange : Colors.grey.shade300)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alt_route, color: _isDestinationFilterOn ? Colors.deepOrange : Colors.grey),
                    const SizedBox(width: 10),
                    Text(_isDestinationFilterOn ? "Đang bật: Về $_preferredAddress" : "Cài đặt điểm đến mong muốn", style: TextStyle(color: _isDestinationFilterOn ? Colors.deepOrange : Colors.grey[700], fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildInTripUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text("Nguyễn Văn Khách"), subtitle: Text("Thanh toán: Tiền mặt - 120k"), trailing: Icon(Icons.phone, color: Colors.green)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), onPressed: () => setState(() => _isInTrip = false), child: const Text("HOÀN THÀNH CHUYẾN ĐI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
      ],
    );
  }
}