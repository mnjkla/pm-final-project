import 'package:dio/dio.dart';
import '../core/api_client.dart'; // Import ApiClient
import '../payload/request/trip_request.dart';
import '../models/trip_model.dart';

class TripService {
  // Dùng Dio từ ApiClient để có chung cấu hình (IP, Timeout...)
  final Dio _dio = ApiClient().dio;

  // File: FE/lib/services/trip_service.dart

  Future<Trip> bookTrip(TripRequest request) async {
    try {
      // SỬA LỖI: Đổi endpoint từ '/trips/book' thành '/trips/create'
      // Backend mapping: @PostMapping("/create") bên trong @RequestMapping("/api/trips")
      final String endpoint = '/trips/create';

      print("🚀 Đang gọi API: ${_dio.options.baseUrl}$endpoint");
      print("📦 Dữ liệu gửi: ${request.toJson()}");

      final response = await _dio.post(
        endpoint,
        data: request.toJson(),
      );

      print("✅ Server phản hồi: ${response.statusCode}");

      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('⏱️ Hết thời gian kết nối (Timeout). Kiểm tra Server!');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('🔌 Không thể kết nối tới Server. Kiểm tra IP/Firewall!');
      } else if (e.response?.statusCode == 405) {
        throw Exception('❌ Lỗi 405: Sai đường dẫn API hoặc phương thức (POST/GET)!');
      }
      throw Exception('Lỗi: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}