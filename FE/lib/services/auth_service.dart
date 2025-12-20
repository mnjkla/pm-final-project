// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart'; // Đảm bảo đúng đường dẫn ApiClient

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Dio _dio = ApiClient().dio;

  // 1. Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Kích hoạt luồng đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng hủy đăng nhập

      // Lấy chi tiết xác thực từ request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Tạo credential mới
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Lỗi Google Sign In: $e");
      rethrow;
    }
  }

  // 2. Đồng bộ User với Backend (Spring Boot)
  Future<void> syncUserToBackend(String role, String name) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      String? token = await currentUser.getIdToken();

      // Gọi API Backend
      final response = await _dio.post(
        '/auth/sync-user',
        data: {
          'role': role, // "DRIVER" hoặc "PASSENGER"
          'name': name,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print("✅ Đồng bộ Backend thành công: ${response.data}");
    } catch (e) {
      print("❌ Lỗi đồng bộ Backend: $e");
      throw Exception("Không thể kết nối với máy chủ.");
    }
  }

  // 3. Đăng xuất
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}