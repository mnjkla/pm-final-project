import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../core/app_colors.dart';
import '../core/api_client.dart';

class DriverTripScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> tripData;

  const DriverTripScreen({super.key, required this.tripId, required this.tripData});

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  // Trạng thái: 0=Đến đón, 1=Đợi khách, 2=Đang đi, 3=Hoàn thành
  int _currentStep = 0;
  String _buttonText = "ĐÃ ĐẾN ĐIỂM ĐÓN";
  Color _buttonColor = Colors.orange;
  bool _isLoading = false;

  // Bản đồ & Vị trí
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(21.0285, 105.8542); // Default
  StreamSubscription<Position>? _positionStream;

  // Dẫn đường
  List<LatLng> _routePoints = []; // Danh sách tọa độ đường đi
  late LatLng _pickupLatLng;
  late LatLng _destLatLng;

  @override
  void initState() {
    super.initState();
    _parseTripCoordinates();
    _startTrackingLocation();

    // Mới vào thì vẽ đường đến điểm đón ngay
    // Delay 1 chút để có vị trí hiện tại rồi mới vẽ
    Future.delayed(const Duration(seconds: 1), () {
      _getRoute(_pickupLatLng);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // 1. Hàm lấy tọa độ từ dữ liệu Trip (Xử lý linh hoạt các trường hợp)
  void _parseTripCoordinates() {
    // Thử lấy tọa độ Pickup
    print("📦 DATA TRIP NHẬN ĐƯỢC: ${widget.tripData}");
    double? pLat = widget.tripData['pickupLat'] ?? widget.tripData['pickupLocation']?['y'] ?? widget.tripData['pickupLocation']?['coordinates']?[1];
    double? pLng = widget.tripData['pickupLng'] ?? widget.tripData['pickupLocation']?['x'] ?? widget.tripData['pickupLocation']?['coordinates']?[0];

    // Thử lấy tọa độ Destination
    double? dLat = widget.tripData['destinationLat'] ?? widget.tripData['destinationLocation']?['y'] ?? widget.tripData['destinationLocation']?['coordinates']?[1];
    double? dLng = widget.tripData['destinationLng'] ?? widget.tripData['destinationLocation']?['x'] ?? widget.tripData['destinationLocation']?['coordinates']?[0];

    // Fallback nếu null (Tránh crash)
    _pickupLatLng = LatLng(pLat ?? 21.0285, pLng ?? 105.8542);
    _destLatLng = LatLng(dLat ?? 21.0285, dLng ?? 105.8542);
  }

  // 2. Theo dõi vị trí tài xế
  void _startTrackingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) return;

    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        // Chỉ auto-center nếu đang di chuyển (để tài xế có thể pan map xem đường)
        // _mapController.move(_currentLocation, 16.0);
      }
    });
  }

  // 3. Hàm lấy tuyến đường từ OSRM (Open Source Routing Machine)
  Future<void> _getRoute(LatLng destination) async {
    // URL OSRM public (Cần đổi sang server riêng nếu dùng production)
    String url = 'http://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation.longitude},${_currentLocation.latitude};' // Từ
        '${destination.longitude},${destination.latitude}' // Đến
        '?overview=full&geometries=geojson';

    try {
      var response = await Dio().get(url);
      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        var coordinates = response.data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
        });

        // Zoom map để thấy toàn bộ đường đi
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(_currentLocation, destination),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } catch (e) {
      print("Lỗi lấy đường đi: $e");
    }
  }

  Future<void> _handleTripAction() async {
    setState(() => _isLoading = true);
    try {
      String endpoint = "";

      if (_currentStep == 0) {
        endpoint = '/trips/${widget.tripId}/arrive';
      } else if (_currentStep == 1) {
        endpoint = '/trips/${widget.tripId}/start';
      } else if (_currentStep == 2) {
        endpoint = '/trips/${widget.tripId}/complete';
      }

      await ApiClient().dio.post(endpoint);

      setState(() {
        if (_currentStep == 0) {
          // Đã đến -> Chờ khách
          _currentStep = 1;
          _buttonText = "BẮT ĐẦU CHUYẾN ĐI";
          _buttonColor = Colors.blue;
          // Có thể xóa đường đi lúc chờ
          _routePoints.clear();
        } else if (_currentStep == 1) {
          // Bắt đầu đi -> Vẽ đường đến điểm trả
          _currentStep = 2;
          _buttonText = "HOÀN THÀNH CHUYẾN";
          _buttonColor = Colors.red;
          _getRoute(_destLatLng); // <--- VẼ ĐƯỜNG ĐẾN ĐÍCH
        } else if (_currentStep == 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Chuyến đi hoàn tất!")));
            Navigator.pop(context);
          }
        }
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đang di chuyển"),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // BẢN ĐỒ
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLocation, initialZoom: 16.0),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),

              // 1. Vẽ đường đi (Polyline)
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent, // Màu đường dẫn
                    ),
                  ],
                ),

              // 2. Các Marker
              MarkerLayer(
                markers: [
                  // Xe tài xế
                  Marker(
                    point: _currentLocation, width: 60, height: 60,
                    child: const Icon(Icons.directions_car, color: AppColors.darkGreen, size: 40),
                  ),
                  // Điểm Đón (Chỉ hiện khi chưa đón)
                  if (_currentStep < 2)
                    Marker(
                      point: _pickupLatLng, width: 80, height: 80,
                      child: const Column(children: [Icon(Icons.location_on, color: Colors.green, size: 40), Text("Đón", style: TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  // Điểm Trả (Luôn hiện hoặc chỉ hiện khi đang đi)
                  Marker(
                    point: _destLatLng, width: 80, height: 80,
                    child: const Column(children: [Icon(Icons.flag, color: Colors.red, size: 40), Text("Đến", style: TextStyle(fontWeight: FontWeight.bold))]),
                  ),
                ],
              ),
            ],
          ),

          // PANEL THÔNG TIN
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(widget.tripData['customerPhone'] ?? "Khách hàng", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_currentStep < 2 ? "Đang đến điểm đón..." : "Đang đến điểm trả..."),
                    trailing: Text("${widget.tripData['price']} đ", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                  ),
                  const Divider(),

                  // Hiển thị địa chỉ mục tiêu hiện tại
                  Row(
                    children: [
                      Icon(_currentStep < 2 ? Icons.my_location : Icons.flag, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentStep < 2
                              ? "Đón: ${widget.tripData['pickupAddress']}"
                              : "Đến: ${widget.tripData['destinationAddress']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleTripAction,
                      style: ElevatedButton.styleFrom(backgroundColor: _buttonColor),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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