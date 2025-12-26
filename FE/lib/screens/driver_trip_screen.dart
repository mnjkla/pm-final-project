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

  // 👇 SỬA 1: Để null ban đầu, không hardcode Hà Nội nữa
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  bool _hasInitialRouteCalculated = false; // Biến cờ để chỉ vẽ đường lần đầu

  // Dẫn đường
  List<LatLng> _routePoints = [];
  late LatLng _pickupLatLng;
  late LatLng _destLatLng;

  @override
  void initState() {
    super.initState();
    _parseTripCoordinates();
    _startTrackingLocation();
    // Không gọi vẽ đường ở đây nữa, mà gọi khi có GPS
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _parseTripCoordinates() {
    print("📦 DATA TRIP: ${widget.tripData}");
    double? pLat = widget.tripData['pickupLat'] ?? widget.tripData['pickupLocation']?['y'];
    double? pLng = widget.tripData['pickupLng'] ?? widget.tripData['pickupLocation']?['x'];
    double? dLat = widget.tripData['destinationLat'] ?? widget.tripData['destinationLocation']?['y'];
    double? dLng = widget.tripData['destinationLng'] ?? widget.tripData['destinationLocation']?['x'];

    // Fallback nếu null (Về Hà Nội hoặc Sài Gòn tùy bạn, nhưng chỉ dùng khi data lỗi)
    _pickupLatLng = LatLng(pLat ?? 21.0285, pLng ?? 105.8542);
    _destLatLng = LatLng(dLat ?? 21.0285, dLng ?? 105.8542);
  }

  // 👇 SỬA 2: Hàm theo dõi vị trí được nâng cấp
  void _startTrackingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) return;

    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        final newLoc = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentLocation = newLoc;
        });

        // 👇 SỬA 3: Chỉ vẽ đường khi lần đầu tiên nhận được tọa độ thật
        if (!_hasInitialRouteCalculated) {
          _hasInitialRouteCalculated = true;
          _mapController.move(newLoc, 16.0); // Zoom ngay vào xe
          _getRoute(_pickupLatLng); // Vẽ đường đến điểm đón
        }
      }
    });
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_currentLocation == null) return; // Chỉ vẽ khi đã có vị trí xe

    String url = 'http://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation!.longitude},${_currentLocation!.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      var response = await Dio().get(url);
      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        var coordinates = response.data['routes'][0]['geometry']['coordinates'] as List;
        if (mounted) {
          setState(() {
            _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
          });
          // Zoom để thấy cả xe và điểm đến
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds(_currentLocation!, destination),
              padding: const EdgeInsets.all(50),
            ),
          );
        }
      }
    } catch (e) {
      print("Lỗi lấy đường đi: $e");
    }
  }

  Future<void> _handleTripAction() async {
    setState(() => _isLoading = true);
    try {
      String endpoint = "";
      if (_currentStep == 0) endpoint = '/trips/${widget.tripId}/arrive';
      else if (_currentStep == 1) endpoint = '/trips/${widget.tripId}/start';
      else if (_currentStep == 2) endpoint = '/trips/${widget.tripId}/complete';

      await ApiClient().dio.post(endpoint);

      setState(() {
        if (_currentStep == 0) {
          _currentStep = 1;
          _buttonText = "BẮT ĐẦU CHUYẾN ĐI";
          _buttonColor = Colors.blue;
          _routePoints.clear(); // Xóa đường cũ
        } else if (_currentStep == 1) {
          _currentStep = 2;
          _buttonText = "HOÀN THÀNH CHUYẾN";
          _buttonColor = Colors.red;
          _getRoute(_destLatLng); // Vẽ đường mới đến điểm trả
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
          // 👇 SỬA 4: Nếu chưa có GPS thì hiện Loading
          _currentLocation == null
              ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Đang định vị xe...")
            ],
          ))
              : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                initialCenter: _currentLocation!, // Chắc chắn không null
                initialZoom: 16.0
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 5.0, color: Colors.blueAccent),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Xe tài xế
                  Marker(
                    point: _currentLocation!,
                    width: 60, height: 60,
                    child: const Icon(Icons.directions_car, color: AppColors.darkGreen, size: 40),
                  ),
                  // Điểm Đón
                  if (_currentStep < 2)
                    Marker(
                      point: _pickupLatLng, width: 80, height: 80,
                      child: const Column(children: [Icon(Icons.location_on, color: Colors.green, size: 40), Text("Đón", style: TextStyle(fontWeight: FontWeight.bold))]),
                    ),
                  // Điểm Trả
                  Marker(
                    point: _destLatLng, width: 80, height: 80,
                    child: const Column(children: [Icon(Icons.flag, color: Colors.red, size: 40), Text("Đến", style: TextStyle(fontWeight: FontWeight.bold))]),
                  ),
                ],
              ),
            ],
          ),

          // PANEL THÔNG TIN
          if (_currentLocation != null) // Chỉ hiện panel khi đã load xong map
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