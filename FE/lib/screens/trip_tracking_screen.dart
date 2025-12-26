import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart'; // Cần cho API đánh giá
import '../core/app_colors.dart';
import '../core/api_client.dart';

class TripTrackingScreen extends StatefulWidget {
  final String tripId;
  final String driverId;
  final double tripPrice; // 👇 THÊM: Truyền giá tiền vào để hiển thị

  const TripTrackingScreen({
    super.key,
    required this.tripId,
    required this.driverId,
    this.tripPrice = 0.0, // Mặc định 0 nếu không truyền
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final MapController _mapController = MapController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  LatLng? _driverLocation; // Nullable để hiện loading
  Map<String, dynamic>? _driverInfo;

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

  // 1. Lấy thông tin tài xế
  void _fetchDriverInfo() async {
    final snapshot = await _dbRef.child('drivers/${widget.driverId}').get();
    if (snapshot.exists) {
      if (mounted) {
        setState(() {
          _driverInfo = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    }
  }

  // 2. Lắng nghe vị trí (Có Log Debug)
  void _listenToDriverLocation() {
    print("📡 Đang lắng nghe vị trí tại node: drivers/${widget.driverId}");

    _driverLocationSub = _dbRef.child('drivers/${widget.driverId}').onValue.listen((event) {
      final data = event.snapshot.value;

      // Chỉ in log khi data thay đổi để tránh spam console quá nhiều, nhưng lúc debug thì cứ in
      // print("📩 Dữ liệu vị trí: $data");

      if (data != null && data is Map) {
        if (data['lat'] != null && data['lng'] != null) {
          final double lat = (data['lat'] is int) ? (data['lat'] as int).toDouble() : data['lat'].toDouble();
          final double lng = (data['lng'] is int) ? (data['lng'] as int).toDouble() : data['lng'].toDouble();

          final newLoc = LatLng(lat, lng);

          if (mounted) {
            setState(() {
              _driverLocation = newLoc;
            });
            _mapController.move(newLoc, 16.0);
          }
        }
      } else {
        print("❌ Chưa nhận được tọa độ. Kiểm tra ID tài xế hoặc trạng thái Online.");
      }
    });
  }

  // 3. Lắng nghe trạng thái hoàn thành
  void _listenToTripStatus() {
    _tripStatusSub = _dbRef.child('trips/${widget.tripId}').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data['status'] == 'COMPLETED') {
        print("✅ Chuyến đi đã hoàn thành!");
        _tripStatusSub?.cancel();
        if (mounted) {
          _showRatingDialog();
        }
      }
    });
  }

  // 4. Dialog Đánh giá (Đã điền code đầy đủ)
  void _showRatingDialog() {
    int selectedStars = 5;
    TextEditingController feedbackController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Text("Đánh giá chuyến đi", style: TextStyle(fontWeight: FontWeight.bold))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Bạn thấy tài xế thế nào?", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setStateDialog(() => selectedStars = index + 1),
                        icon: Icon(
                          index < selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.amber, size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: feedbackController,
                    decoration: const InputDecoration(
                      hintText: "Gửi lời nhắn...",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
                    onPressed: isSubmitting ? null : () async {
                      setStateDialog(() => isSubmitting = true);
                      try {
                        await ApiClient().dio.post(
                            '/trips/${widget.tripId}/rate',
                            queryParameters: {'stars': selectedStars, 'feedback': feedbackController.text}
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cảm ơn bạn!")));
                        }
                      } catch (e) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Text("GỬI ĐÁNH GIÁ"),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _callDriver() {
    final phone = _driverInfo?['phone'] ?? '';
    if (phone.isNotEmpty) launchUrl(Uri.parse("tel:$phone"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BẢN ĐỒ
          _driverLocation == null
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Đang định vị tài xế..."),
              ],
            ),
          )
              : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                initialCenter: _driverLocation!,
                initialZoom: 16.0
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _driverLocation!,
                    width: 50, height: 50,
                    child: const Icon(Icons.directions_car, color: AppColors.darkGreen, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // THÔNG TIN TÀI XẾ
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(_driverInfo?['avatarUrl'] ?? "https://i.pravatar.cc/150?img=11"),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_driverInfo?['name'] ?? "Tài xế SmartTaxi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text("${_driverInfo?['vehicleType'] ?? 'Xe'} • ${_driverInfo?['plate'] ?? '...'}", style: const TextStyle(color: Colors.grey)),
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                Text(" 5.0", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _callDriver,
                        style: IconButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        icon: const Icon(Icons.phone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Cước phí:"),
                        // 👇 SỬA 3: Hiển thị giá tiền truyền vào
                        Text(
                            "${widget.tripPrice.toStringAsFixed(0)} đ",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontSize: 16)
                        ),
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