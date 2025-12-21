import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Import để dùng kIsWeb

class ApiClient {
  // Tự động chọn URL phù hợp
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api'; // Chạy trên Web
    } else {
      return 'http://192.168.1.18:8080/api';  // Chạy trên Android Emulator
    }
  }

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30), // Tăng timeout lên 10s
    receiveTimeout: const Duration(seconds: 30),
  ));

  Dio get dio => _dio;
}