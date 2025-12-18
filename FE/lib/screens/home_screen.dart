import 'dart:async';
import 'dart:math' as math; // Import thư viện toán học để tính khoảng cách
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart'; // Dùng để gọi API vẽ đường (OSRM)
import '../core/app_colors.dart';
import '../services/driver_service.dart';
import '../models/driver_model.dart';
import '../services/place_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DriverService _driverService = DriverService();
  final PlaceService _placeService = PlaceService();
  final MapController _mapController = MapController();
  final Dio _dio = Dio(); // Client gọi API vẽ đường

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  // --- STATE VARIABLES ---
  LatLng? _currentPosition;
  LatLng _centerMapPosition = const LatLng(10.762622, 106.660172);
  LatLng? _pickupLocation;
  LatLng? _destLocation;

  List<DriverModel> _drivers = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<LatLng> _routePoints = []; // Danh sách tọa độ vẽ đường

  bool _isLoading = true;
  bool _isDragging = false;
  bool _isSelectingPickup = true;
  Timer? _debounce;

  // --- Payment & Pricing ---
  String _selectedPaymentMethod = "Tiền mặt"; // Mặc định
  double _tripDistanceKm = 0.0; // Khoảng cách chuyến đi

  // Bảng giá cơ bản (VND/km)
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
      _centerMapPosition = _currentPosition!;
      _isLoading = false;
      _pickupLocation = _currentPosition;
      _getAddressFromLatLng(_currentPosition!, isPickup: true);
    });
    _fetchNearbyDrivers();
  }

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

  // Giữ nguyên hàm này
  // Tìm hàm này và thay thế nội dung bên trong
  Future<void> _getAddressFromLatLng(LatLng point, {required bool isPickup}) async {

    // --- SỬA ĐOẠN NÀY ---
    // Gọi API lấy tên đường thật thay vì hiển thị số
    String address = await _placeService.getPlaceName(point.latitude, point.longitude);
    // -------------------

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

    // Nếu đã có cả 2 điểm -> Vẽ đường (tắt autoZoom khi đang kéo tay)
    if (_pickupLocation != null && _destLocation != null) {
      _getRoute(autoZoom: false);
    }
  }

  // --- MỚI: HÀM VẼ ĐƯỜNG & TÍNH KHOẢNG CÁCH (Dùng OSRM Free API) ---
  Future<void> _getRoute({bool autoZoom = false}) async {
    if (_pickupLocation == null || _destLocation == null) return;

    // URL OSRM (Open Source Routing Machine) - Miễn phí
    String url = 'http://router.project-osrm.org/route/v1/driving/'
        '${_pickupLocation!.longitude},${_pickupLocation!.latitude};'
        '${_destLocation!.longitude},${_destLocation!.latitude}'
        '?overview=full&geometries=geojson';

    try {
      var response = await _dio.get(url);
      if (response.statusCode == 200) {
        var data = response.data;
        var routes = data['routes'];
        if (routes.isNotEmpty) {
          var geometry = routes[0]['geometry'];
          var coordinates = geometry['coordinates'] as List;

          // 1. Lấy danh sách điểm để vẽ Polyline
          List<LatLng> points = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          // 2. Lấy khoảng cách (mét) -> đổi ra km
          double distanceMeters = routes[0]['distance'].toDouble();

          setState(() {
            _routePoints = points;
            _tripDistanceKm = distanceMeters / 1000;
          });

          // Zoom bản đồ để thấy toàn bộ đường đi
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
    // Tính toán khung hình bao quanh tuyến đường
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
        padding: const EdgeInsets.all(50), // Chừa lề
      ),
    );
  }

  // --- UI LOGIC ---
  void _onInputTapped(bool isPickup) {
    setState(() {
      _isSelectingPickup = isPickup;
      // Nếu tap vào ô nào thì di chuyển camera về điểm đó
      if (isPickup && _pickupLocation != null) {
        _mapController.move(_pickupLocation!, 16.0);
        _centerMapPosition = _pickupLocation!;
      } else if (!isPickup && _destLocation != null) {
        _mapController.move(_destLocation!, 16.0);
        _centerMapPosition = _destLocation!;
      }
    });
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _isDragging = true;
        _centerMapPosition = camera.center;
        _searchResults = [];
      });
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () {
        setState(() => _isDragging = false);
        _getAddressFromLatLng(_centerMapPosition, isPickup: _isSelectingPickup);
        if (_isSelectingPickup) _fetchNearbyDrivers();
      });
    }
  }

  void _onSearchResultSelected(Map<String, dynamic> place) {
    FocusScope.of(context).unfocus();
    LatLng selectedPos = LatLng(place['lat'], place['lng']);

    setState(() {
      _searchResults = [];
      _centerMapPosition = selectedPos;
    });

    // Cập nhật địa chỉ
    _getAddressFromLatLng(selectedPos, isPickup: _isSelectingPickup);

    // Di chuyển map đến điểm chọn
    _mapController.move(selectedPos, 16.0);

    if (_isSelectingPickup) _fetchNearbyDrivers();

    // --- SỬA ĐOẠN NÀY ---
    // Khi tìm kiếm xong, chỉ vẽ đường chứ KHÔNG ZOOM (để ghim không bị chạy)
    if (_pickupLocation != null && _destLocation != null) {
      _getRoute(autoZoom: false); // <--- Đặt là false
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

  // --- DIALOG CHỌN THANH TOÁN ---
  void _showPaymentSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chọn phương thức thanh toán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              _buildPaymentOption("Tiền mặt", Icons.money),
              _buildPaymentOption("Ví Momo", Icons.account_balance_wallet, color: Colors.pink),
              _buildPaymentOption("Thẻ ATM/Visa", Icons.credit_card, color: Colors.blue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String name, IconData icon, {Color color = Colors.green}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 30),
      title: Text(name),
      trailing: _selectedPaymentMethod == name ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: () {
        setState(() => _selectedPaymentMethod = name);
        Navigator.pop(context);
      },
    );
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
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smarttaxi.app',
              ),
              // --- VẼ ĐƯỜNG ĐI (POLYLINE) ---
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // --- 1. CHẤM XANH VỊ TRÍ THỰC TẾ (Luôn hiển thị) ---
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7), // Màu xanh nhạt
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 5)],
                        ),
                      ),
                    ),

                  // --- 2. Marker Điểm đón / Điểm đến (Logic cũ giữ nguyên) ---
                  if (_pickupLocation != null && !_isSelectingPickup)
                    Marker(point: _pickupLocation!, width: 40, height: 40, child: const Icon(Icons.my_location, color: Colors.blue, size: 40)),
                  // ... (Các marker khác giữ nguyên)
                ],
              ),
            ],
          ),

          // 2. PIN GHIM
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: _isDragging ? 40 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                    child: Text(_isSelectingPickup ? "Chỉnh điểm đón" : "Chỉnh điểm đến", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(height: 5),
                  Icon(_isSelectingPickup ? Icons.my_location : Icons.location_on, size: 50, color: _isSelectingPickup ? Colors.blue : Colors.red),
                ],
              ),
            ),
          ),

          // 3. KHỐI NHẬP LIỆU
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
          // ... (Phần Khối nhập liệu ở trên)

          // --- 4. CÁC NÚT CHỨC NĂNG (Định vị & Refresh) ---
          Positioned(
            bottom: 300, // Đẩy lên cao hơn bảng giá một chút
            right: 20,
            child: Column(
              children: [
                // Nút Refresh tìm lại tài xế
                FloatingActionButton(
                  heroTag: "btnRefresh",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _fetchNearbyDrivers,
                  child: const Icon(Icons.refresh, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                // Nút Định Vị (Quay về chỗ tôi)
                FloatingActionButton(
                  heroTag: "btnLocate",
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    await _determinePosition(); // Lấy lại GPS
                    if (_currentPosition != null) {
                      _mapController.move(_currentPosition!, 16.0); // Bay về chỗ cũ
                      // Reset điểm đón về chỗ tôi
                      setState(() {
                        _isSelectingPickup = true;
                        _pickupLocation = _currentPosition;
                      });
                      _getAddressFromLatLng(_currentPosition!, isPickup: true);
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
          ),

          // ... (Phần Bảng dịch vụ & Thanh toán ở dưới cùng giữ nguyên)
          // 4. BẢNG DỊCH VỤ & THANH TOÁN
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
                  // --- HIỂN THỊ KHOẢNG CÁCH ---
                  if (_routePoints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Khoảng cách: ${_tripDistanceKm.toStringAsFixed(1)} km", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),

                          // --- NÚT CHỌN THANH TOÁN ---
                          InkWell(
                            onTap: _showPaymentSelector,
                            child: Row(
                              children: [
                                Icon(Icons.payment, color: Colors.green[700], size: 20),
                                const SizedBox(width: 5),
                                Text(_selectedPaymentMethod, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                  // --- DANH SÁCH XE & GIÁ TIỀN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildServiceButton(Icons.two_wheeler, "Bike", "Bike"),
                      _buildServiceButton(Icons.directions_car, "Car", "Car"),
                      _buildServiceButton(Icons.inventory_2, "Delivery", "Delivery"),
                    ],
                  ),

                  const SizedBox(height: 15),
                  // Nút ĐẶT XE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                      onPressed: (_routePoints.isEmpty) ? null : () {
                        // TODO: Gọi API Đặt chuyến (Create Trip)
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tìm tài xế...")));
                      },
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

  // Widget hiển thị nút xe + Giá tiền
  Widget _buildServiceButton(IconData icon, String label, String type) {
    // Tính giá tiền = (Khoảng cách * Đơn giá)
    int price = 0;
    if (_tripDistanceKm > 0) {
      price = (_tripDistanceKm * _priceRates[type]!).round();
    }

    return Column(children: [
      CircleAvatar(radius: 28, backgroundColor: AppColors.primaryGreen.withOpacity(0.1), child: Icon(icon, color: AppColors.darkGreen, size: 28)),
      const SizedBox(height: 5),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 2),
      // Hiển thị giá tiền (định dạng 15k, 20k)
      if (price > 0)
        Text("${(price/1000).toStringAsFixed(0)}k", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black))
      else
        const Text("--", style: TextStyle(color: Colors.grey)),
    ]);
  }

  Widget _buildLocationInput({required IconData icon, required Color iconColor, required String hint, required TextEditingController controller, required bool isActive, required VoidCallback onTap, required Function(String) onChanged}) {
    return Row(children: [
      const SizedBox(width: 15), Icon(icon, color: iconColor, size: 24), const SizedBox(width: 15),
      Expanded(child: TextField(controller: controller, onTap: onTap, onChanged: onChanged, style: TextStyle(fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15), suffixIcon: controller.text.isNotEmpty && isActive ? IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () { controller.clear(); onChanged(''); }) : null))),
    ]);
  }
}