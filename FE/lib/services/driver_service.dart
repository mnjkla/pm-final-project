import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/driver_model.dart';

class DriverService {
  final ApiClient _apiClient = ApiClient();

  Future<List<DriverModel>> getNearbyDrivers(double lat, double lng,{double radius = 5.0}) async {
    try {
      final response = await _apiClient.dio.get(
        '/drivers/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
          'limit': 200,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => DriverModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Lỗi lấy danh sách tài xế: $e');
      return [];
    }
  }
}