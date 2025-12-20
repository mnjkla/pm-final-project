import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class PlaceService {
  // SỬA LẠI: Thêm BaseOptions để cấu hình Header
  final Dio _dio = Dio(BaseOptions(
    headers: {
      // BẮT BUỘC: Phải có User-Agent để OSM biết ai đang gọi
      'User-Agent': 'SmartTaxiApp/1.0 (smarttaxi.contact@gmail.com)',
      // Tùy chọn: Ưu tiên tiếng Việt
      'Accept-Language': 'vi-VN',
    },
    // Tăng thời gian chờ lên 1 chút để tránh lỗi Timeout nếu mạng lag
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 1. Tìm kiếm địa điểm
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
          'addressdetails': 1,
          'countrycodes': 'vn',
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data.map((place) => {
          'name': place['display_name'],
          'lat': double.parse(place['lat']),
          'lng': double.parse(place['lon']),
        }));
      }
    } catch (e) {
      print("⚠️ Lỗi tìm kiếm: $e");
    }
    return [];
  }

  // 2. Lấy tên địa chỉ từ tọa độ
  Future<String> getPlaceName(double lat, double lng) async {
    try {
      // Thêm độ trễ nhỏ 1s để tránh spam request liên tục gây lỗi 429/503
      await Future.delayed(const Duration(seconds: 1));

      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': 18,
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200) {
        return response.data['display_name'] ?? "Vị trí không xác định";
      }
    } catch (e) {
      print("⚠️ Lỗi lấy địa chỉ (OSM): $e");
    }
    // Trả về tọa độ nếu lỗi
    return "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
  }
}