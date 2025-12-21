import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Dio _dio = ApiClient().dio;

  // --- 1. GOOGLE SIGN IN (Giữ nguyên) ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Lỗi Google Sign In: $e");
      rethrow;
    }
  }

  // --- 2. EMAIL SIGN UP (Đăng ký mới) ---
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Lỗi Đăng ký Email: $e");
      rethrow;
    }
  }

  // --- 3. EMAIL SIGN IN (Đăng nhập mới) ---
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Lỗi Đăng nhập Email: $e");
      rethrow;
    }
  }

  // --- 4. ĐỒNG BỘ BACKEND (Giữ nguyên logic cũ) ---
  Future<void> syncUserToBackend({
    required String role,
    required String name,
    required String phone,
    String? vehicleType,
    String? vehiclePlate,
    String? vehicleBrand,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Cập nhật tên hiển thị lên Firebase nếu chưa có (cho trường hợp đăng ký Email)
      if (currentUser.displayName == null || currentUser.displayName != name) {
        await currentUser.updateDisplayName(name);
      }

      String? token = await currentUser.getIdToken();

      final Map<String, dynamic> data = {
        'role': role,
        'name': name,
        'phone': phone,
      };

      if (role == 'DRIVER') {
        data['vehicleType'] = vehicleType;
        data['vehiclePlate'] = vehiclePlate;
        data['vehicleBrand'] = vehicleBrand;
      }

      final response = await _dio.post(
        '/auth/sync-user',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      print("✅ Đồng bộ Backend thành công: ${response.data}");
    } catch (e) {
      print("❌ Lỗi đồng bộ Backend: $e");
      throw Exception("Không thể kết nối với máy chủ.");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  // ... (Code cũ giữ nguyên)

  // API MỚI: Lấy thông tin User hiện tại
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception("Chưa đăng nhập Firebase");

      String? token = await currentUser.getIdToken();

      final response = await _dio.get(
        '/auth/profile', // Gọi vào API Java vừa viết
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data; // Trả về Map (role, data)
    } catch (e) {
      print("❌ Lỗi lấy Profile: $e");
      throw Exception("Không thể lấy thông tin người dùng.");
    }
  }
}