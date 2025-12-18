import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class PlaceService {
  final Dio _dio = Dio();

  // 1. Tìm kiếm địa điểm theo từ khóa (Giữ nguyên cũ)
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
      print("Lỗi tìm kiếm: $e");
    }
    return [];
  }

  // 2. (MỚI) Lấy tên địa chỉ từ tọa độ (Reverse Geocoding)
  Future<String> getPlaceName(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': 18, // Zoom 18 để lấy số nhà/tên đường chính xác
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200) {
        // Lấy tên hiển thị đầy đủ
        return response.data['display_name'] ?? "Vị trí không xác định";
      }
    } catch (e) {
      print("Lỗi lấy địa chỉ: $e");
    }
    // Nếu lỗi thì trả về tọa độ tạm
    return "${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}";
  }
}