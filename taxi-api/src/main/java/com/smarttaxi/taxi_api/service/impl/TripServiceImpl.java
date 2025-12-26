package com.smarttaxi.taxi_api.service.impl;

import java.time.LocalTime;
import java.util.List;

import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Service;

import com.smarttaxi.taxi_api.model.entity.Driver;
import com.smarttaxi.taxi_api.model.entity.PriceConfig;
import com.smarttaxi.taxi_api.model.entity.Trip;
import com.smarttaxi.taxi_api.model.enums.TripStatus;
import com.smarttaxi.taxi_api.payload.request.TripRequest;
import com.smarttaxi.taxi_api.repository.DriverRepository;
import com.smarttaxi.taxi_api.repository.PriceConfigRepository; 
import com.smarttaxi.taxi_api.repository.TripRepository;
import com.smarttaxi.taxi_api.service.FirebaseService;
import com.smarttaxi.taxi_api.service.TripService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TripServiceImpl implements TripService {
    // Trong Class TripServiceImpl

 
    @Override
    public Trip getDriverCurrentTrip(String driverId) {
        // Lấy danh sách chuyến của tài xế
        List<Trip> trips = tripRepository.findByDriverId(driverId);
        if (trips.isEmpty()) return null;
        
        // Sắp xếp lấy chuyến mới nhất
        trips.sort((t1, t2) -> t2.getCreatedAt().compareTo(t1.getCreatedAt()));
        Trip latestTrip = trips.get(0);

        // 👇 SỬA ĐOẠN NÀY: Kiểm tra 3 trạng thái đang hoạt động
        // DRIVER_ACCEPTED: Tài xế đã nhận, đang đến đón
        // DRIVER_ARRIVED: Tài xế đã đến điểm đón
        // ONGOING: Đang chở khách
        if (latestTrip.getStatus() == TripStatus.DRIVER_ACCEPTED || 
            latestTrip.getStatus() == TripStatus.DRIVER_ARRIVED ||
            latestTrip.getStatus() == TripStatus.ONGOING) {
            return latestTrip;
        }
        
        return null;
    }

    private final TripRepository tripRepository;
    private final DriverRepository driverRepository;
    private final PriceConfigRepository priceConfigRepository;
    private final FirebaseService firebaseService;


    @Override
    public Trip createTrip(TripRequest request) {
        // 1. Lấy tọa độ đón (Giữ nguyên logic)
        Point pickupPoint = new Point(request.getPickupLongitude(), request.getPickupLatitude());
        
        // =========================================================================
        // 🔴 BẮT ĐẦU ĐOẠN "FIX CỨNG" (HARDCODE)
        // Thay vì tìm theo bán kính/online, ta lấy TẤT CẢ tài xế trong DB
        // =========================================================================
        
        List<Driver> candidates = driverRepository.findAll();

        if (candidates.isEmpty()) {
            throw new RuntimeException("❌ Lỗi Demo: Database rỗng! Hãy tạo ít nhất 1 tài xế.");
        }

        // 👉 LẤY LUÔN TÀI XẾ ĐẦU TIÊN TÌM THẤY (Bất chấp vị trí, trạng thái)
        Driver bestDriver = candidates.get(0);

        // In log ra console server để bạn biết nó đang bắt vào tài xế nào
        System.out.println("🔥 DEMO MODE ACTIVATED 🔥");
        System.out.println("✅ Đã bắt dính tài xế: " + bestDriver.getName());
        System.out.println("🆔 Driver ID: " + bestDriver.getId());
        
        // =========================================================================
        // 🔴 KẾT THÚC ĐOẠN FIX CỨNG
        // =========================================================================

        // 4. TÍNH GIÁ TIỀN (Giữ nguyên logic cũ)
        double estimatedKm = calculateDistanceKm(
            request.getPickupLatitude(), request.getPickupLongitude(),
            request.getDestinationLatitude(), request.getDestinationLongitude()
        );
        
        double finalPrice = calculateDynamicPrice(request.getVehicleType(), estimatedKm);

        // 5. Tạo chuyến đi và lưu xuống DB
        Trip newTrip = new Trip();
        newTrip.setDriverId(bestDriver.getId());
        newTrip.setCustomerId(request.getCustomerId());
        newTrip.setPickupLocation(new GeoJsonPoint(request.getPickupLongitude(), request.getPickupLatitude()));
        newTrip.setDestinationLocation(new GeoJsonPoint(request.getDestinationLongitude(), request.getDestinationLatitude()));
        newTrip.setPickupAddress(request.getPickupAddress());
        newTrip.setDestinationAddress(request.getDestinationAddress());
        
        newTrip.setDistance(estimatedKm);
        newTrip.setPrice(finalPrice);
        newTrip.setStatus(TripStatus.PENDING); 
        
        Trip savedTrip = tripRepository.save(newTrip);
        
        // Gửi thông báo sang máy tài xế đó
        if (bestDriver.getFirebaseId() != null) {
            firebaseService.notifyDriverNewTrip(bestDriver.getFirebaseId(), savedTrip);
            System.out.println("📨 Đã gửi tin nhắn tới Firebase ID: " + bestDriver.getFirebaseId());
        } else {
            System.out.println("❌ LỖI: Tài xế này chưa có Firebase ID! Hãy cập nhật DB ngay.");
        }
        return savedTrip;
    }
    // --- Helper: Tính điểm tài xế ---

    private double calculateDriverScore(Driver driver) {
        
        double ratingScore = (driver.getRating() == null) ? 5.0 : driver.getRating();
        double acceptanceScore = (driver.getAcceptanceRate() == null) ? 1.0 : driver.getAcceptanceRate();
        
        return (ratingScore * 0.7) + (acceptanceScore * 10 * 0.3);
    }

    // --- Helper: Tính giá tiền động ---
    private double calculateDynamicPrice(String vehicleType, double distanceKm) {
        LocalTime now = LocalTime.now();
        
        // Tìm cấu hình giá phù hợp với khung giờ hiện tại
        // Lưu ý: priceConfigRepository cần hàm tìm kiếm theo Type và Time
        PriceConfig config = priceConfigRepository.findByVehicleTypeAndJwtTime(vehicleType, now)
                .orElse(new PriceConfig("DEFAULT", 10000.0, 5000.0, 1.0, null, null)); // Giá fallback

        double rawPrice = config.getBaseFare() + (distanceKm * config.getPricePerKm());
        return rawPrice * config.getSurgeMultiplier();
    }

    // --- Helper: Tính khoảng cách Haversine (tạm thời) ---
    private double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371; // Bán kính trái đất (km)
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }
    public Trip driverAcceptTrip(String tripId) {
        Trip trip = tripRepository.findById(tripId).orElseThrow(() -> new RuntimeException("Trip not found"));
        
        if (trip.getStatus() != TripStatus.PENDING) {
            throw new RuntimeException("Chuyến đi không còn khả dụng!");
        }

        trip.setStatus(TripStatus.DRIVER_ACCEPTED);
        tripRepository.save(trip);

        // Xóa request trên Firebase để app tài xế ẩn thông báo
        firebaseService.clearDriverRequest(trip.getDriverId());
        
        return trip;
    }
    public void driverRejectTrip(String tripId) {
        Trip trip = tripRepository.findById(tripId).orElseThrow();
        
        // Logic đơn giản: Hủy chuyến hoặc tìm tài xế khác (ở đây demo hủy trước)
        trip.setStatus(TripStatus.CANCELLED); 
        tripRepository.save(trip);

        firebaseService.clearDriverRequest(trip.getDriverId());
    }
    @Override
    public Trip getTrip(String id) {
        return tripRepository.findById(id).orElse(null);
    }
    // File: com.smarttaxi.taxi_api.service.impl.TripServiceImpl

    @Override
    public Trip driverArriveAtPickup(String tripId) {
        Trip trip = tripRepository.findById(tripId).orElseThrow(() -> new RuntimeException("Trip not found"));
        // Cập nhật trạng thái: Đã đến điểm đón
        trip.setStatus(TripStatus.DRIVER_ARRIVED);
        return tripRepository.save(trip);
    }

    @Override
    public Trip driverStartTrip(String tripId) {
        Trip trip = tripRepository.findById(tripId).orElseThrow();
        // Cập nhật trạng thái: Đang chở khách
        trip.setStatus(TripStatus.ONGOING);
        return tripRepository.save(trip);
    }

    // File: com.smarttaxi.taxi_api.service.impl.TripServiceImpl.java

    @Override
    public Trip driverCompleteTrip(String tripId) {
        // 1. Tìm chuyến đi
        Trip trip = tripRepository.findById(tripId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy chuyến đi: " + tripId));

        // 2. Tìm tài xế
        Driver driver = driverRepository.findById(trip.getDriverId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy tài xế!"));

        // 3. TÍNH TOÁN THU NHẬP (TRỪ 20% PHÍ DỊCH VỤ)
        double totalPrice = trip.getPrice();           // Tổng tiền khách trả (Ví dụ: 100.000đ)
        double serviceFee = totalPrice * 0.20;         // Phí sàn 20% (20.000đ)
        double driverIncome = totalPrice - serviceFee; // Tài xế nhận 80% (80.000đ)

        // 4. Cộng tiền vào ví
        if (driver.getWalletBalance() == null) {
            driver.setWalletBalance(0.0);
        }
        double currentBalance = driver.getWalletBalance();
        driver.setWalletBalance(currentBalance + driverIncome);

        // 5. Lưu thông tin tài xế
        driverRepository.save(driver);

        // In log để kiểm tra (Debug)
        System.out.println("✅ HOÀN THÀNH CUỐC XE: " + tripId);
        System.out.println("💵 Tổng thu: " + totalPrice + " VNĐ");
        System.out.println("📉 Phí sàn (20%): -" + serviceFee + " VNĐ");
        System.out.println("💰 Cộng ví tài xế: +" + driverIncome + " VNĐ");
        System.out.println("💳 Số dư ví mới: " + driver.getWalletBalance() + " VNĐ");

        // 6. Cập nhật trạng thái chuyến đi và lưu
        trip.setStatus(TripStatus.COMPLETED);
        return tripRepository.save(trip);
    }
}