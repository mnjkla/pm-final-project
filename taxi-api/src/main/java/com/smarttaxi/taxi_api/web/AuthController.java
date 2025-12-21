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

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final DriverRepository driverRepository;
    private final PassengerRepository passengerRepository;

    // --- 1. HÀM ĐĂNG KÝ / ĐỒNG BỘ USER (Hàm này bị thiếu lúc nãy) ---
    @PostMapping("/sync-user")
    public ResponseEntity<?> syncUser(@RequestHeader("Authorization") String token, 
                                      @RequestBody Map<String, String> userInfo) {
        try {
            // 1. Xác thực Token
            String idToken = token.replace("Bearer ", "");
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            String uid = decodedToken.getUid();
            
            String role = userInfo.get("role"); // "DRIVER" hoặc "PASSENGER"
            String name = userInfo.get("name");
            String phone = userInfo.get("phone"); // Lấy thêm số điện thoại

            // 2. Xử lý lưu DB
            if ("DRIVER".equalsIgnoreCase(role)) {
                Driver driver = driverRepository.findByFirebaseId(uid).orElse(new Driver());
                
                driver.setFirebaseId(uid);
                driver.setName(name);
                driver.setPhone(phone);
                
                // Cập nhật thông tin xe
                driver.setVehicleType(userInfo.get("vehicleType"));   
                driver.setVehiclePlate(userInfo.get("vehiclePlate")); 
                driver.setVehicleBrand(userInfo.get("vehicleBrand"));
                
                driverRepository.save(driver);
                return ResponseEntity.ok(driver);

            } else {
                Passenger passenger = passengerRepository.findByFirebaseId(uid).orElse(new Passenger());
                passenger.setFirebaseId(uid);
                passenger.setName(name);
                passenger.setPhoneNumber(phone); // Lưu ý: setPhoneNumber (Passenger) vs setPhone (Driver)
                
                passengerRepository.save(passenger);
                return ResponseEntity.ok(passenger);
            }

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Lỗi xác thực: " + e.getMessage());
        }
    }

    // --- 2. HÀM LẤY PROFILE (Hàm phân quyền) ---
    @GetMapping("/profile")
    public ResponseEntity<?> getUserProfile(@RequestHeader("Authorization") String token) {
        try {
            String idToken = token.replace("Bearer ", "");
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            String uid = decodedToken.getUid();

            // Tìm trong bảng TÀI XẾ
            Optional<Driver> driver = driverRepository.findByFirebaseId(uid);
            if (driver.isPresent()) {
                return ResponseEntity.ok(Map.of("role", "DRIVER", "data", driver.get()));
            }

            // Tìm trong bảng KHÁCH HÀNG
            Optional<Passenger> passenger = passengerRepository.findByFirebaseId(uid);
            if (passenger.isPresent()) {
                return ResponseEntity.ok(Map.of("role", "PASSENGER", "data", passenger.get()));
            }

            // Không tìm thấy -> Người dùng MỚI
            return ResponseEntity.ok(Map.of("role", "NEW"));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Lỗi Token: " + e.getMessage());
        }
    }
}