import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../core/app_colors.dart';
import '../services/driver_service.dart';
import '../models/driver_model.dart';
import '../services/place_service.dart';
import '../payload/request/trip_request.dart';
import '../services/trip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Services
  final DriverService _driverService = DriverService();
  final PlaceService _placeService = PlaceService();
  final TripService _tripService = TripService();
  final MapController _mapController = MapController();
  final Dio _dio = Dio();

  // Controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  // State Variables
  LatLng _centerMapPosition = const LatLng(10.762622, 106.660172);
  LatLng? _pickupLocation;
  LatLng? _destLocation;

  List<DriverModel> _drivers = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<LatLng> _routePoints = [];

  bool _isLoading = true;
  bool _isDragging = false;
  bool _isSelectingPickup = true;
  Timer? _debounce;

  // Payment & Vehicle
  String _selectedPaymentMethod = "Tiền mặt";
  String _selectedVehicle = "Bike";
  double _tripDistanceKm = 0.0;

  final Map<String, int> _priceRates = {
    "Bike": 6000,
    "Car": 15000,
    "Delivery": 8000,
  };

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // 1. Lấy vị trí GPS ban đầu
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (mounted) {
      setState(() {
        LatLng currentPos = LatLng(position.latitude, position.longitude);
        _centerMapPosition = currentPos;
        _pickupLocation = currentPos;
        _isLoading = false;
        // Lần đầu vào app thì cho phép Auto Zoom và lấy địa chỉ
        _getAddressFromLatLng(currentPos, isPickup: true, autoZoom: true);
      });
      _mapController.move(_centerMapPosition, 16.0);
      _fetchNearbyDrivers();
    }
  }

  // 2. Tìm tài xế
  Future<void> _fetchNearbyDrivers() async {
    LatLng searchCenter = _pickupLocation ?? _centerMapPosition;
    try {
      final drivers = await _driverService.getNearbyDrivers(
        searchCenter.latitude,
        searchCenter.longitude,
        radius: 5.0,
      );
      if (mounted) setState(() => _drivers = drivers);
    } catch (_) {}
  }

  // --- [UPDATE QUAN TRỌNG] Lấy địa chỉ thật từ API ---
  Future<void> _getAddressFromLatLng(LatLng point, {required bool isPickup, bool autoZoom = false}) async {
    // Gọi PlaceService để lấy tên đường thật (123 Le Loi...)
    String address = await _placeService.getPlaceName(point.latitude, point.longitude);

    if (!mounted) return;
    setState(() {
      if (isPickup) {
        _pickupController.text = address;
        _pickupLocation = point;
      } else {
        _destController.text = address;
        _destLocation = point;
      }
    });

    // Nếu đủ 2 điểm thì vẽ đường (truyền tham số autoZoom vào)
    if (_pickupLocation != null && _destLocation != null) {
      _getRoute(autoZoom: autoZoom);
    }
  }

  // --- [UPDATE QUAN TRỌNG] Vẽ đường với tùy chọn Zoom ---
  Future<void> _getRoute({bool autoZoom = false}) async {
    if (_pickupLocation == null || _destLocation == null) return;

    String url = 'http://router.project-osrm.org/route/v1/driving/'
        '${_pickupLocation!.longitude},${_pickupLocation!.latitude};'
        '${_destLocation!.longitude},${_destLocation!.latitude}'
        '?overview=full&geometries=geojson';

    try {
      var response = await _dio.get(url);
      if (response.statusCode == 200) {
        var routes = response.data['routes'];
        if (routes.isNotEmpty) {
          var coordinates = routes[0]['geometry']['coordinates'] as List;
          List<LatLng> points = coordinates.map((c) => LatLng(c[1], c[0])).toList();
          double distanceMeters = routes[0]['distance'].toDouble();

          setState(() {
            _routePoints = points;
            _tripDistanceKm = distanceMeters / 1000;
          });

          // CHỈ ZOOM KHI ĐƯỢC PHÉP
          if (autoZoom) {
            _fitBounds();
          }
        }
      }
    } catch (e) {
      print("Lỗi vẽ đường: $e");
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;
    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // UI Events
  void _onInputTapped(bool isPickup) {
    setState(() {
      _isSelectingPickup = isPickup;
      if (isPickup && _pickupLocation != null) {
        _mapController.move(_pickupLocation!, 16.0);
        _centerMapPosition = _pickupLocation!;
      } else if (!isPickup && _destLocation != null) {
        _mapController.move(_destLocation!, 16.0);
        _centerMapPosition = _destLocation!;
      }
    });
  }

  // --- [LOGIC MỚI] Khi kéo Map, KHÔNG Zoom, chỉ cập nhật địa chỉ ---
  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _isDragging = true;
        _centerMapPosition = camera.center;
        _searchResults = [];
      });

      // Debounce để tránh gọi API liên tục khi đang kéo
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        setState(() => _isDragging = false);
        // autoZoom = false vì người dùng đang chủ động kéo
        _getAddressFromLatLng(_centerMapPosition, isPickup: _isSelectingPickup, autoZoom: false);
        if (_isSelectingPickup) _fetchNearbyDrivers();
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) { setState(() => _searchResults = []); return; }
      final results = await _placeService.searchPlaces(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    });
  }

  // --- [LOGIC MỚI] Khi chọn kết quả tìm kiếm ---
  void _onSearchResultSelected(Map<String, dynamic> place) {
    FocusScope.of(context).unfocus();
    LatLng selectedPos = LatLng(place['lat'], place['lng']);
    setState(() {
      _searchResults = [];
      _centerMapPosition = selectedPos;
    });

    // autoZoom = false để giữ người dùng ở điểm vừa chọn
    _getAddressFromLatLng(selectedPos, isPickup: _isSelectingPickup, autoZoom: false);
    _mapController.move(selectedPos, 16.0);

    if (_isSelectingPickup) _fetchNearbyDrivers();
  }

  // Gọi API Đặt xe
  void _onBookTrip() async {
    if (_pickupLocation == null) return;
    setState(() => _isLoading = true);

    final request = TripRequest(
      pickupLatitude: _pickupLocation!.latitude,
      pickupLongitude: _pickupLocation!.longitude,
      pickupAddress: _pickupController.text,
      destinationLatitude: _destLocation?.latitude,
      destinationLongitude: _destLocation?.longitude,
      destinationAddress: _destController.text,
      vehicleType: _selectedVehicle.toUpperCase(),
    );

    try {
      final trip = await _tripService.bookTrip(request);
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Đã tìm thấy tài xế! Mã: ${trip.id} - Giá: ${(_tripDistanceKm * _priceRates[_selectedVehicle]!).toStringAsFixed(0)}đ"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Lỗi: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerMapPosition,
              initialZoom: 16.0,
              onTap: (_, __) => FocusScope.of(context).unfocus(),
              onPositionChanged: _onMapPositionChanged, // Đã cập nhật logic kéo
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttaxi.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 4.0, color: Colors.blueAccent),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_pickupLocation != null && !_isSelectingPickup)
                    Marker(point: _pickupLocation!, width: 40, height: 40, child: const Icon(Icons.my_location, color: Colors.blue, size: 40)),
                  if (_destLocation != null && _isSelectingPickup)
                    Marker(point: _destLocation!, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
                  ..._drivers.map((driver) => Marker(
                    point: LatLng(driver.latitude, driver.longitude),
                    width: 40, height: 40,
                    child: const Icon(Icons.directions_car, color: AppColors.darkGreen, size: 30),
                  )),
                ],
              ),
            ],
          ),

          // 2. PIN (Center)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDragging)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                      child: Text(_isSelectingPickup ? "Thả để chọn điểm đón" : "Thả để chọn điểm đến", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  const SizedBox(height: 5),
                  Icon(_isSelectingPickup ? Icons.my_location : Icons.location_on, size: 50, color: _isSelectingPickup ? Colors.blue : Colors.red),
                ],
              ),
            ),
          ),

          // 3. UI SEARCH & LOCATION INPUT
          Positioned(
            top: 50, left: 20, right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(15),
                    boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      _buildLocationInput(icon: Icons.my_location, iconColor: Colors.blue, hint: "Điểm đón", controller: _pickupController, isActive: _isSelectingPickup, onTap: () => _onInputTapped(true), onChanged: _onSearchChanged),
                      const Divider(height: 1, indent: 50, endIndent: 20),
                      _buildLocationInput(icon: Icons.location_on, iconColor: Colors.red, hint: "Điểm đến", controller: _destController, isActive: !_isSelectingPickup, onTap: () => _onInputTapped(false), onChanged: _onSearchChanged),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: ListView.separated(
                      padding: EdgeInsets.zero, shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final place = _searchResults[index];
                        return ListTile(title: Text(place['name']), leading: const Icon(Icons.place, color: Colors.grey), onTap: () => _onSearchResultSelected(place));
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 4. LOCATION BUTTON
          Positioned(
            bottom: 300, right: 20,
            child: FloatingActionButton(
              onPressed: () => _determinePosition(), // Reset về vị trí mình
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // 5. BOTTOM SHEET (Price & Book)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_routePoints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Khoảng cách: ${_tripDistanceKm.toStringAsFixed(1)} km", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Row(
                            children: [
                              Icon(Icons.payment, color: Colors.green[700], size: 20),
                              const SizedBox(width: 5),
                              Text(_selectedPaymentMethod, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                            ],
                          )
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildServiceButton(Icons.two_wheeler, "Bike", "Bike"),
                      _buildServiceButton(Icons.directions_car, "Car", "Car"),
                      _buildServiceButton(Icons.inventory_2, "Delivery", "Delivery"),
                    ],
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                      onPressed: (_routePoints.isEmpty) ? null : _onBookTrip,
                      child: const Text("ĐẶT XE NGAY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),

          if (_isLoading) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildServiceButton(IconData icon, String label, String type) {
    bool isSelected = _selectedVehicle == type;
    int price = 0;
    if (_tripDistanceKm > 0) {
      price = (_tripDistanceKm * _priceRates[type]!).round();
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = type),
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGreen.withOpacity(0.2) : Colors.grey[100],
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: AppColors.primaryGreen, width: 2) : null,
            ),
            child: Icon(icon, color: isSelected ? AppColors.primaryGreen : Colors.grey, size: 28)
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.black : Colors.grey)),
        const SizedBox(height: 2),
        if (price > 0)
          Text("${(price/1000).toStringAsFixed(0)}k", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black))
        else
          const Text("--", style: TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _buildLocationInput({required IconData icon, required Color iconColor, required String hint, required TextEditingController controller, required bool isActive, required VoidCallback onTap, required Function(String) onChanged}) {
    return Row(children: [
      const SizedBox(width: 15), Icon(icon, color: iconColor, size: 24), const SizedBox(width: 15),
      Expanded(child: TextField(controller: controller, onTap: onTap, onChanged: onChanged, style: TextStyle(fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15), suffixIcon: controller.text.isNotEmpty && isActive ? IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () { controller.clear(); onChanged(''); }) : null))),
    ]);
  }
}