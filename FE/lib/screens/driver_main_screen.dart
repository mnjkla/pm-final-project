import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart'; // Để vẽ đường (Polyline)

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/place_service.dart'; // [MỚI] Import PlaceService
import 'login_screen.dart';

import '../core/api_client.dart';
class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  bool _isDialogShowing = false;
  int _selectedIndex = 0;

  final MapController _mapController = MapController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PlaceService _placeService = PlaceService(); // [MỚI]
  final Dio _dio = Dio(); // [MỚI] Để gọi API vẽ đường


  LatLng _currentLocation = const LatLng(21.0285, 105.8542);
  bool _isOnline = false;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;

  // --- [MỚI] BIẾN CHO CHẾ ĐỘ TIỆN ĐƯỜNG ---
  LatLng? _convenienceDest;       // Tọa độ điểm muốn về
  String _convenienceAddress = ""; // Địa chỉ điểm muốn về
  List<LatLng> _routePoints = [];  // Đường vẽ trên bản đồ
  List<Map<String, dynamic>> _searchResults = []; // Kết quả tìm kiếm
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  StreamSubscription<DatabaseEvent>? _requestSubscription;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _listenForTripRequests();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _listenForTripRequests() {
    final user = _auth.currentUser;
    if (user == null) return;

    _requestSubscription = _dbRef.child('drivers/${user.uid}/trip_request').onValue.listen((event) {
      final data = event.snapshot.value;

      // TRƯỜNG HỢP 1: CÓ REQUEST MỚI
      if (data != null && !_isDialogShowing) {
        final requestMap = Map<String, dynamic>.from(data as Map);
        _isDialogShowing = true; // Đánh dấu đang hiện

        _showTripRequestDialog(requestMap).then((_) {
          _isDialogShowing = false; // Khi đóng dialog thì reset về false
        });
      }
      // TRƯỜNG HỢP 2: REQUEST BỊ HỦY/MẤT (data == null) MÀ DIALOG ĐANG HIỆN
      else if (data == null && _isDialogShowing) {
        Navigator.of(context).pop(); // Đóng dialog ngay lập tức
      }
    });
  }
  // Cũ: void _showTripRequestDialog(...)
  // Mới: Thêm Future<void> và return
  Future<void> _showTripRequestDialog(Map<String, dynamic> request) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          // ... (giữ nguyên nội dung bên trong)
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ... code giao diện của bạn
              const Text("🚖 YÊU CẦU CHUYẾN ĐI MỚI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
              // ...
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Đóng dialog
                        _rejectTrip(request['tripId']);
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      child: const Text("TỪ CHỐI"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Đóng dialog
                        _acceptTrip(request['tripId']);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
                      child: const Text("NHẬN CHUYẾN"),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
  Future<void> _acceptTrip(String tripId) async {
    try {
      // Gọi API Backend: POST /api/trips/{id}/accept
      // Lưu ý: Thay ApiClient().dio bằng instance Dio của bạn
      final response = await Dio().post('http://192.168.100.240:8080/api/trips/$tripId/accept');
      print("LOG: Đang gọi API: $url");
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã nhận chuyến thành công!")));
        // Điều hướng sang màn hình đón khách (DriverTripScreen)
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> _rejectTrip(String tripId) async {
    try {
      await Dio().post('http://192.168.100.240:8080/api/trips/$tripId/reject');
    } catch (e) {
      print("Lỗi từ chối: $e");
    }
  }


  Future<void> _determinePosition() async {

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_currentLocation, 16.0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- [MỚI] LOGIC TÌM ĐỊA ĐIỂM ---
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    // Debounce đơn giản
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_searchController.text != query) return;
      final results = await _placeService.searchPlaces(query);
      if (mounted) setState(() => _searchResults = results);
    });
  }

  void _selectConvenienceDest(Map<String, dynamic> place) async {
    FocusScope.of(context).unfocus();
    LatLng dest = LatLng(place['lat'], place['lng']);

    setState(() {
      _convenienceDest = dest;
      _convenienceAddress = place['name'];
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
    });

    // Vẽ đường từ vị trí xe đến điểm tiện chuyến
    _getRouteToDest(dest);

    // Cập nhật lên Firebase
    _updateDriverStatusToFirebase();

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚗 Đã bật chế độ tiện đường về: $_convenienceAddress"), backgroundColor: Colors.blue)
    );
  }

  // --- [MỚI] VẼ ĐƯỜNG VỀ ---
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
        // Zoom để thấy cả 2 điểm
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
    _updateDriverStatusToFirebase();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã tắt chế độ tiện đường"), backgroundColor: Colors.grey)
    );
  }

  // --- CẬP NHẬT FIREBASE ---
  void _updateDriverStatusToFirebase() {
    final user = _auth.currentUser;
    if (user == null) return;

    Map<String, dynamic> updateData = {
      'status': _isOnline ? 'ONLINE' : 'OFFLINE',
      'last_updated': ServerValue.timestamp,
    };

    // Nếu đang bật tiện chuyến, gửi thêm thông tin
    if (_convenienceDest != null) {
      updateData['destination_filter'] = {
        'lat': _convenienceDest!.latitude,
        'lng': _convenienceDest!.longitude,
        'address': _convenienceAddress
      };
    } else {
      updateData['destination_filter'] = null; // Xóa filter
    }

    _dbRef.child('drivers/${user.uid}').update(updateData);
  }

  void _toggleOnline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isOnline = !_isOnline);

    if (_isOnline) {
      const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        final newLoc = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() => _currentLocation = newLoc);
          _mapController.move(newLoc, 16.0);
        }

        // Update cả vị trí + thông tin tiện chuyến (nếu có)
        Map<String, dynamic> liveUpdate = {
          'lat': position.latitude,
          'lng': position.longitude,
          'angle': position.heading,
          'status': 'ONLINE',
          'last_updated': ServerValue.timestamp,
        };
        if (_convenienceDest != null) {
          liveUpdate['destination_filter'] = {
            'lat': _convenienceDest!.latitude,
            'lng': _convenienceDest!.longitude,
            'address': _convenienceAddress
          };
        }
        _dbRef.child('drivers/${user.uid}').update(liveUpdate);
      });
    } else {
      _positionStream?.cancel();
      _dbRef.child('drivers/${user.uid}').update({'status': 'OFFLINE'});
    }
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        // 1. MAP
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 16.0,
            onTap: (_, __) => setState(() { _isSearching = false; FocusScope.of(context).unfocus(); }), // Ẩn tìm kiếm khi chạm map
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            // Vẽ đường tiện chuyến (Màu cam để phân biệt)
            if (_routePoints.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(points: _routePoints, strokeWidth: 4.0, color: Colors.orangeAccent),
              ]),
            MarkerLayer(
              markers: [
                // Marker Xe
                Marker(
                  point: _currentLocation, width: 60, height: 60,
                  child: const Icon(Icons.directions_car, color: AppColors.darkGreen, size: 40),
                ),
                // Marker Điểm tiện chuyến
                if (_convenienceDest != null)
                  Marker(
                    point: _convenienceDest!, width: 50, height: 50,
                    child: const Icon(Icons.flag, color: Colors.orange, size: 40),
                  )
              ],
            ),
          ],
        ),

        // 2. SEARCH BAR & STATUS (Header)
        Positioned(
          top: 50, left: 15, right: 15,
          child: Column(
            children: [
              // Thanh trạng thái Online
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

              // [MỚI] Thanh tiện đường (Hiển thị khi đang Set hoặc bấm tìm kiếm)
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

                      // List kết quả tìm kiếm
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

        // 3. NÚT KÍCH HOẠT TIỆN CHUYẾN (Góc dưới trái)
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

        // 4. Nút về vị trí (Góc dưới phải)
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

  // (Giữ nguyên các tab Earnings và Profile như cũ)
  Widget _buildEarningsTab() => const Center(child: Text("Thu nhập"));
  Widget _buildProfileTab() => Center(
      child: ElevatedButton(onPressed: () async { await AuthService().signOut(); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); }, child: const Text("Đăng xuất"))
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Tránh vỡ layout khi hiện bàn phím
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