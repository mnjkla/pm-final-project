import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'driver_trip_screen.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/place_service.dart';
import 'login_screen.dart';
import '../core/api_client.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  // --- 1. BIẾN QUẢN LÝ TRẠNG THÁI ---
  final MapController _mapController = MapController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PlaceService _placeService = PlaceService();
  final Dio _dio = Dio();
  double _walletBalance = 0.0;

  LatLng _currentLocation = const LatLng(21.0285, 105.8542); // Mặc định Hà Nội
  bool _isOnline = false;
  bool _isLoading = true;
  int _selectedIndex = 0;

  // Quản lý Stream (Lắng nghe dữ liệu)
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DatabaseEvent>? _tripRequestSubscription;
  bool _isDialogShowing = false;

  // --- BIẾN CHO CHẾ ĐỘ TIỆN ĐƯỜNG ---
  LatLng? _convenienceDest;
  String _convenienceAddress = "";
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // ============================================================
  // 🟢 VÒNG ĐỜI WIDGET (INIT & DISPOSE)
  // ============================================================
  @override
  void initState() {
    super.initState();
    _determinePosition();
    final uid = _auth.currentUser?.uid;
    print("🆔 ID TÀI XẾ ĐANG ĐĂNG NHẬP: $uid");// Lấy vị trí hiện tại
    _listenToTripRequests();   // Bắt đầu lắng nghe cuốc xe từ Firebase
    _fetchWalletBalance();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _tripRequestSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // 📍 XỬ LÝ VỊ TRÍ & TRẠNG THÁI ONLINE
  // ============================================================
  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_currentLocation, 16.0);

        // Nếu vào app là tự bật Online luôn (Tùy chọn)
        _toggleOnline(true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _fetchWalletBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Gọi API: GET /api/drivers/profile/{uid}
      final response = await ApiClient().dio.get('/drivers/profile/$uid');

      if (response.statusCode == 200) {
        setState(() {
          // Lấy field 'walletBalance' từ JSON trả về
          _walletBalance = (response.data['walletBalance'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      print("Lỗi lấy số dư: $e");
    }
  }

  void _toggleOnline([bool? forceState]) async {
    final user = _auth.currentUser;
    if (user == null) return;

    bool newState = forceState ?? !_isOnline;

    setState(() => _isOnline = newState);

    if (_isOnline) {
      // Bắt đầu theo dõi vị trí real-time
      const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        final newLoc = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() => _currentLocation = newLoc);
          _mapController.move(newLoc, 16.0);
        }
        _updateDriverStatusToFirebase(newLoc);
      });
    } else {
      // Tắt theo dõi
      _positionStream?.cancel();
      _dbRef.child('drivers/${user.uid}').update({'status': 'OFFLINE'});
    }
  }

  void _updateDriverStatusToFirebase(LatLng loc) {
    final user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> updateData = {
      'lat': loc.latitude,
      'lng': loc.longitude,
      'status': 'ONLINE',
      'last_updated': ServerValue.timestamp,
    };

    // Nếu có tiện chuyến thì gửi thêm filter
    if (_convenienceDest != null) {
      updateData['destination_filter'] = {
        'lat': _convenienceDest!.latitude,
        'lng': _convenienceDest!.longitude,
        'address': _convenienceAddress
      };
    } else {
      updateData['destination_filter'] = null;
    }

    _dbRef.child('drivers/${user.uid}').update(updateData);
  }

  // ============================================================
  // 🚀 LẮNG NGHE YÊU CẦU ĐẶT XE (FIREBASE LISTENER)
  // ============================================================
  void _listenToTripRequests() {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _dbRef.child('drivers/$uid/trip_request');

    _tripRequestSubscription = ref.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data != null && !_isDialogShowing) {
        // Có khách mới -> Hiện Popup
        _showRequestDialog(Map<String, dynamic>.from(data as Map));
      } else if (data == null && _isDialogShowing) {
        // Khách hủy hoặc đã nhận -> Đóng Popup
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        _isDialogShowing = false;
      }
    });
  }

  // ============================================================
  // 🎨 HIỂN THỊ POPUP NHẬN CHUYẾN
  // ============================================================
  void _showRequestDialog(Map<String, dynamic> requestData) {
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("🔔 CÓ KHÁCH ĐẶT XE!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📍 Đón: ${requestData['pickupAddress']}"),
            const SizedBox(height: 10),
            Text("🏁 Đến: ${requestData['destinationAddress']}"),
            const SizedBox(height: 10),
            Text("💰 Giá: ${requestData['price']} VNĐ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("📏 Xa: ${requestData['distance']} km"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _rejectTrip(requestData['tripId']);
              Navigator.of(ctx).pop();
              _isDialogShowing = false;
            },
            child: const Text("Bỏ qua", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
            onPressed: () {
              _acceptTrip(requestData['tripId'],requestData);
              Navigator.of(ctx).pop();
              _isDialogShowing = false;
            },
            child: const Text("NHẬN CHUYẾN"),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔗 GỌI API BACKEND (ACCEPT / REJECT)
  // ============================================================
  Future<void> _acceptTrip(String tripId, Map<String, dynamic> requestData) async {
    try {
      // 1. Gọi API nhận chuyến
      // Sử dụng ApiClient cho chuẩn
      final response = await ApiClient().dio.post('/trips/$tripId/accept');

      if (response.statusCode == 200) {
        if (mounted) {
          // 2. Tắt thông báo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Đã nhận chuyến! Đang chuyển hướng...")),
          );

          // 3. CHUYỂN HƯỚNG SANG MÀN HÌNH HÀNH TRÌNH
          // Trong hàm _acceptTrip, đoạn Navigator.push
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverTripScreen(
                tripId: tripId,
                tripData: requestData,
              ),
            ),
          ).then((_) {
            // 👇 THÊM DÒNG NÀY: Khi quay lại từ màn hình Trip -> Gọi API cập nhật tiền ngay
            _fetchWalletBalance();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  Future<void> _rejectTrip(String tripId) async {
    try {
      await ApiClient().dio.post('/trips/$tripId/reject');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Đã từ chối.")));
      }
    } catch (e) {
      print("Lỗi từ chối: $e");
    }
  }

  // ============================================================
  // 🛠️ TÍNH NĂNG TIỆN CHUYẾN & TÌM ĐỊA ĐIỂM
  // ============================================================
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_searchController.text != query) return;
      final results = await _placeService.searchPlaces(query);
      if (mounted) setState(() => _searchResults = results);
    });
  }

  void _selectConvenienceDest(Map<String, dynamic> place) {
    FocusScope.of(context).unfocus();
    LatLng dest = LatLng(place['lat'], place['lng']);

    setState(() {
      _convenienceDest = dest;
      _convenienceAddress = place['name'];
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
    });

    _getRouteToDest(dest);
    _updateDriverStatusToFirebase(_currentLocation); // Update ngay lên Firebase

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🚗 Tiện đường về: $_convenienceAddress")));
  }

  Future<void> _getRouteToDest(LatLng dest) async {
    String url = 'http://router.project-osrm.org/route/v1/driving/'
        '${_currentLocation.longitude},${_currentLocation.latitude};'
        '${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson';
    try {
      var response = await _dio.get(url);
      if (response.statusCode == 200 && response.data['routes'].isNotEmpty) {
        var coordinates = response.data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _routePoints = coordinates.map((c) => LatLng(c[1], c[0])).toList();
        });
        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds(_currentLocation, dest),
          padding: const EdgeInsets.all(50),
        ));
      }
    } catch (e) {
      print("Lỗi vẽ đường: $e");
    }
  }

  void _cancelConvenienceMode() {
    setState(() {
      _convenienceDest = null;
      _convenienceAddress = "";
      _routePoints = [];
    });
    _updateDriverStatusToFirebase(_currentLocation);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã tắt chế độ tiện đường")));
  }

  // ============================================================
  // 📱 GIAO DIỆN CHÍNH (BUILD)
  // ============================================================
  Widget _buildHomeTab() {
    return Stack(
      children: [
        // 1. BẢN ĐỒ
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 16.0,
            onTap: (_, __) => setState(() { _isSearching = false; FocusScope.of(context).unfocus(); }),
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            if (_routePoints.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(points: _routePoints, strokeWidth: 4.0, color: Colors.orangeAccent),
              ]),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation, width: 60, height: 60,
                  child: const Icon(Icons.directions_car, color: AppColors.darkGreen, size: 40),
                ),
                if (_convenienceDest != null)
                  Marker(
                    point: _convenienceDest!, width: 50, height: 50,
                    child: const Icon(Icons.flag, color: Colors.orange, size: 40),
                  )
              ],
            ),
          ],
        ),

        // 2. THANH TRẠNG THÁI & TÌM KIẾM
        Positioned(
          top: 50, left: 15, right: 15,
          child: Column(
            children: [
              // Trạng thái Online/Offline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isOnline ? "Đang hoạt động" : "Đang ngoại tuyến", style: TextStyle(fontWeight: FontWeight.bold, color: _isOnline ? Colors.green : Colors.grey)),
                    Switch(value: _isOnline, activeColor: Colors.green, onChanged: (_) => _toggleOnline()),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Tìm kiếm tiện chuyến
              if (_isSearching || _convenienceDest != null)
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]),
                  child: Column(
                    children: [
                      if (_convenienceDest == null)
                        TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: const InputDecoration(
                              hintText: "Nhập địa chỉ muốn về...",
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 15)
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      if (_convenienceDest != null)
                        ListTile(
                          leading: const Icon(Icons.alt_route, color: Colors.orange),
                          title: const Text("Đang tiện đường về:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          subtitle: Text(_convenienceAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: _cancelConvenienceMode),
                        ),

                      // Kết quả tìm kiếm
                      if (_searchResults.isNotEmpty && _convenienceDest == null)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_,__) => const Divider(height: 1),
                            itemBuilder: (ctx, i) => ListTile(
                              title: Text(_searchResults[i]['name']),
                              onTap: () => _selectConvenienceDest(_searchResults[i]),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
            ],
          ),
        ),

        // 3. NÚT CHỨC NĂNG
        if (!_isSearching && _convenienceDest == null)
          Positioned(
            bottom: 100, left: 20,
            child: FloatingActionButton.extended(
              heroTag: "btnConvenience",
              onPressed: () => setState(() => _isSearching = true),
              backgroundColor: Colors.white,
              icon: const Icon(Icons.alt_route, color: Colors.orange),
              label: const Text("Tiện đường", style: TextStyle(color: Colors.black)),
            ),
          ),

        Positioned(
          bottom: 20, right: 20,
          child: FloatingActionButton(
            heroTag: "btnLoc",
            onPressed: _determinePosition,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet, size: 80, color: AppColors.darkGreen),
          const SizedBox(height: 20),
          const Text("Thu nhập hiện tại", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 10),

          // Hiển thị số tiền từ biến _walletBalance
          Text(
            "${_walletBalance.toStringAsFixed(0)} VNĐ", // Format số nguyên
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          ),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _fetchWalletBalance, // Bấm để làm mới số tiền
            icon: const Icon(Icons.refresh),
            label: const Text("Cập nhật số dư"),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
          )
        ],
      ),
    );
  }
  Widget _buildProfileTab() => Center(
      child: ElevatedButton(onPressed: () async { await AuthService().signOut(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); }, child: const Text("Đăng xuất"))
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : [_buildHomeTab(), _buildEarningsTab(), _buildProfileTab()][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.darkGreen,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Thu nhập"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cá nhân"),
        ],
      ),
    );
  }
}