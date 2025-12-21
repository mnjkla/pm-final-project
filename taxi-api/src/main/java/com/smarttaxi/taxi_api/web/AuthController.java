package com.smarttaxi.taxi_api.web;

import java.util.Map;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import com.smarttaxi.taxi_api.model.entity.Driver;
import com.smarttaxi.taxi_api.model.entity.Passenger;
import com.smarttaxi.taxi_api.repository.DriverRepository;
import com.smarttaxi.taxi_api.repository.PassengerRepository;

import lombok.RequiredArgsConstructor;

// File: com/smarttaxi/taxi_api/web/AuthController.java
// ... (Giữ nguyên các import cũ)
import java.util.Optional; // Đảm bảo đã import Optional

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final DriverRepository driverRepository;
    private final PassengerRepository passengerRepository;

    // ... (Giữ nguyên hàm syncUser cũ) ...

    // --- THÊM ĐOẠN NÀY VÀO ---
    @GetMapping("/profile")
    public ResponseEntity<?> getUserProfile(@RequestHeader("Authorization") String token) {
        try {
            // 1. Xác thực Token
            String idToken = token.replace("Bearer ", "");
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            String uid = decodedToken.getUid();

            // 2. Tìm trong bảng TÀI XẾ
            Optional<Driver> driver = driverRepository.findByFirebaseId(uid);
            if (driver.isPresent()) {
                // Trả về: { "role": "DRIVER", "data":ObjectDriver }
                return ResponseEntity.ok(Map.of("role", "DRIVER", "data", driver.get()));
            }

            // 3. Tìm trong bảng KHÁCH HÀNG
            Optional<Passenger> passenger = passengerRepository.findByFirebaseId(uid);
            if (passenger.isPresent()) {
                // Trả về: { "role": "PASSENGER", "data":ObjectPassenger }
                return ResponseEntity.ok(Map.of("role", "PASSENGER", "data", passenger.get()));
            }

            // 4. Không tìm thấy ở đâu -> Người dùng MỚI (Cần đăng ký)
            return ResponseEntity.ok(Map.of("role", "NEW"));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Lỗi Token: " + e.getMessage());
        }
    }
}