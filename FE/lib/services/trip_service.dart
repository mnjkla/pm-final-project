import 'package:dio/dio.dart';
import '../core/api_client.dart'; // Import ApiClient
import '../payload/request/trip_request.dart';
import '../models/trip_model.dart';

class TripService {
  // Dùng Dio từ ApiClient để có chung cấu hình (IP, Timeout...)
  final Dio _dio = ApiClient().dio;

  Future<Trip> bookTrip(TripRequest request) async {
    try {
      print("🚀 Đang gọi API: ${_dio.options.baseUrl}/trips/book");
      print("📦 Dữ liệu gửi: ${request.toJson()}");

      final response = await _dio.post(
        '/trips/book', // Không cần gõ lại baseUrl
        data: request.toJson(),
      );

      print("✅ Server phản hồi: ${response.statusCode}");

      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Xử lý lỗi chi tiết hơn từ Dio
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('⏱️ Hết thời gian kết nối (Timeout). Kiểm tra Server!');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('🔌 Không thể kết nối tới Server. Kiểm tra IP/Firewall!');
      }
      throw Exception('Lỗi: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}