package com.smarttaxi.taxi_api.service.impl;

import java.time.LocalTime;
import java.util.Comparator;
import java.util.List;

import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Metrics;
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
        

        // 1. Lấy tọa độ đón
        Point pickupPoint = new Point(request.getPickupLongitude(), request.getPickupLatitude());
        
        // 2. Tìm tài xế Online trong bán kính 3km, rating >= 3.0
        Distance radius = new Distance(3, Metrics.KILOMETERS);
        List<Driver> candidates = driverRepository.findByIsOnlineTrueAndLocationNearAndRatingGreaterThanEqual(
                pickupPoint, radius, 3.0
        );

        if (candidates.isEmpty()) {
            throw new RuntimeException("Không tìm thấy tài xế phù hợp gần bạn!");
        }

        // 3. THUẬT TOÁN SCORING: Chọn tài xế tốt nhất
        // Công thức: Điểm = (Rating * 4) + (Tỷ lệ nhận * 2)
        // (Đây là logic đơn giản hóa, thực tế có thể phức tạp hơn)
        Driver bestDriver = candidates.stream()
            .max(Comparator.comparingDouble(this::calculateDriverScore))
            .orElse(candidates.get(0));

        // 4. TÍNH GIÁ TIỀN (DYNAMIC PRICING)
        // Tính khoảng cách ước lượng (Code thực tế nên dùng Google Maps API để chính xác)
        double estimatedKm = calculateDistanceKm(
            request.getPickupLatitude(), request.getPickupLongitude(),
            request.getDestinationLatitude(), request.getDestinationLongitude()
        );
        
        double finalPrice = calculateDynamicPrice(request.getVehicleType(), estimatedKm);

        // 5. Tạo chuyến đi
        Trip newTrip = new Trip();
        newTrip.setDriverId(bestDriver.getId());
        newTrip.setCustomerId(request.getCustomerId()); // Giả sử request có field này
        newTrip.setPickupLocation(new GeoJsonPoint(request.getPickupLongitude(), request.getPickupLatitude()));
        newTrip.setDestinationLocation(new GeoJsonPoint(request.getDestinationLongitude(), request.getDestinationLatitude()));
        newTrip.setPickupAddress(request.getPickupAddress());
        newTrip.setDestinationAddress(request.getDestinationAddress());
        
        // Set giá và trạng thái
        newTrip.setDistance(estimatedKm);
        newTrip.setPrice(finalPrice);
        newTrip.setStatus(TripStatus.PENDING); // Hoặc WAITING_DRIVER tùy flow
        Trip savedTrip = tripRepository.save(newTrip);
        firebaseService.notifyDriverNewTrip(bestDriver.getId(), savedTrip);

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
}