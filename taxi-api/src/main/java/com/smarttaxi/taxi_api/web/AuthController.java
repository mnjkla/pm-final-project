package com.smarttaxi.taxi_api.web;

// 1. Import các thư viện Spring Boot
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor;

// 2. Import thư viện Firebase
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;

// 3. Import các Class trong dự án của bạn (Model, Repository)
import com.smarttaxi.taxi_api.model.entity.Driver;
import com.smarttaxi.taxi_api.model.entity.Passenger;
import com.smarttaxi.taxi_api.repository.DriverRepository;
import com.smarttaxi.taxi_api.repository.PassengerRepository;

// 4. Import tiện ích Java
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final DriverRepository driverRepository;
    private final PassengerRepository passengerRepository;

    @PostMapping("/sync-user")
    public ResponseEntity<?> syncUser(@RequestHeader("Authorization") String token, 
                                      @RequestBody Map<String, String> userInfo) {
        try {
            // 1. Cắt chuỗi "Bearer " để lấy token sạch
            String idToken = token.replace("Bearer ", "");
            
            // 2. Xác thực với Firebase Admin SDK
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            String uid = decodedToken.getUid(); // Đây là UID của Firebase
            String role = userInfo.get("role"); // "DRIVER" hoặc "PASSENGER"

            // 3. Kiểm tra và Lưu vào MongoDB
            if ("DRIVER".equalsIgnoreCase(role)) {
                // Tìm tài xế, nếu chưa có thì tạo mới
                Driver driver = driverRepository.findByFirebaseId(uid).orElse(new Driver());
                
                driver.setFirebaseId(uid);
                // getPhoneNumber() có thể null nếu đăng nhập bằng Google/Facebook
                // Nên kiểm tra trước khi set nếu cần thiết
                // driver.setPhoneNumber(decodedToken.getPhoneNumber()); 
                
                driver.setName(userInfo.get("name"));
                
                // Lưu xuống DB
                driverRepository.save(driver);
                return ResponseEntity.ok(driver);
            } else {
                // Tìm khách hàng, nếu chưa có thì tạo mới
                Passenger passenger = passengerRepository.findByFirebaseId(uid).orElse(new Passenger());
                
                passenger.setFirebaseId(uid);
                passenger.setName(userInfo.get("name"));
                
                // Lưu xuống DB
                passengerRepository.save(passenger);
                return ResponseEntity.ok(passenger);
            }

        } catch (Exception e) {
            // Trả về lỗi 401 nếu Token sai
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Token không hợp lệ: " + e.getMessage());
        }
    }
}