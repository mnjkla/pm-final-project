import 'package:dio/dio.dart';
import '../payload/request/trip_request.dart';
import '../models/trip_model.dart';

class TripService {
  final Dio _dio = Dio();

  // LƯU Ý QUAN TRỌNG VỀ IP:
  // - Nếu chạy trên Máy ảo Android (Emulator): Dùng 10.0.2.2
  // - Nếu chạy trên Điện thoại thật: Dùng IP LAN của máy tính (ví dụ 192.168.1.15)
  // - Nếu chạy trên Web: Dùng localhost
  static const String baseUrl = 'http://10.0.2.2:8080/api/trips';

  Future<Trip> bookTrip(TripRequest request) async {
    try {
      print("Đang gọi API: $baseUrl/book");
      print("Dữ liệu gửi: ${request.toJson()}");

      final response = await _dio.post(
        '$baseUrl/book',
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true, // Không báo lỗi nếu status != 200 để tự xử lý
        ),
      );

      print("Server phản hồi: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Lỗi Server: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      throw Exception('Không thể kết nối tới Server: $e');
    }
  }
}