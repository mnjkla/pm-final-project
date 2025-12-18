package com.smarttaxi.taxi_api.service.impl;

import com.smarttaxi.taxi_api.model.entity.Driver;
import com.smarttaxi.taxi_api.model.entity.Trip;
import com.smarttaxi.taxi_api.model.enums.TripStatus;
import com.smarttaxi.taxi_api.repository.DriverRepository;
import com.smarttaxi.taxi_api.repository.TripRepository;
import com.smarttaxi.taxi_api.service.TripService;
import com.smarttaxi.taxi_api.payload.request.TripRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TripServiceImpl implements TripService {

    // SỬA LỖI: Xóa "= null" và "=". Để nguyên khai báo final để Lombok tự xử lý Injection.
    private final TripRepository tripRepository;
    private final DriverRepository driverRepository;

    @Override
    public Trip createTrip(TripRequest request) {
        // 1. Chuẩn bị dữ liệu địa lý
        // Point dùng để tính toán tìm kiếm (Spring Data Geo)
        Point searchPoint = new Point(request.getPickupLongitude(), request.getPickupLatitude());
        
        // 2. Tìm tài xế đang Online trong bán kính 2km
        Distance radius = new Distance(2, Metrics.KILOMETERS);
        List<Driver> nearbyDrivers = driverRepository.findByIsOnlineTrueAndLocationNear(searchPoint, radius);

        if (nearbyDrivers.isEmpty()) {
            throw new RuntimeException("Rất tiếc, không tìm thấy tài xế nào quanh đây!");
        }

        // 3. Tạo chuyến đi mới
        Trip newTrip = new Trip();
        
        // LƯU Ý: Entity Trip dùng GeoJsonPoint để lưu trữ chuẩn MongoDB
        newTrip.setPickupLocation(new GeoJsonPoint(request.getPickupLongitude(), request.getPickupLatitude()));
        newTrip.setPickupAddress(request.getPickupAddress());

        // Xử lý điểm đến (nếu khách có chọn)
        if (request.getDestinationLongitude() != null && request.getDestinationLatitude() != null) {
            newTrip.setDestinationLocation(new GeoJsonPoint(request.getDestinationLongitude(), request.getDestinationLatitude()));
            newTrip.setDestinationAddress(request.getDestinationAddress());
        }

        // Gán tài xế (Lấy người đầu tiên tìm thấy - Logic đơn giản nhất)
        Driver selectedDriver = nearbyDrivers.get(0); 
        newTrip.setDriverId(selectedDriver.getId());
        newTrip.setStatus(TripStatus.DRIVER_ACCEPTED); 
        
        // Có thể lưu thêm CustomerId nếu sau này có Token xác thực
        // newTrip.setCustomerId(SecurityContextHolder...);

        return tripRepository.save(newTrip);
    }

    @Override
    public Trip getTrip(String id) {
        return tripRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Trip not found with id: " + id));
    }
}