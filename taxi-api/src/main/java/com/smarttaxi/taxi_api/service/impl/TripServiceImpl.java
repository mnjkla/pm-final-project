package com.smarttaxi.taxi_api.service.impl;

import com.smarttaxi.taxi_api.model.entity.Driver;
import com.smarttaxi.taxi_api.model.entity.Trip;
import com.smarttaxi.taxi_api.model.enums.TripStatus;
import com.smarttaxi.taxi_api.repository.DriverRepository;
import com.smarttaxi.taxi_api.repository.TripRepository;
import com.smarttaxi.taxi_api.service.TripService;
import com.smarttaxi.taxi_api.payload.request.TripRequest;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
// XÓA @RequiredArgsConstructor VÌ NÓ LÀ CỦA LOMBOK
public class TripServiceImpl implements TripService {

    private final TripRepository tripRepository;
    private final DriverRepository driverRepository;

    // --- TỰ VIẾT CONSTRUCTOR THAY CHO LOMBOK ---
    // Spring sẽ dùng cái này để tiêm (Inject) repository vào
    public TripServiceImpl(TripRepository tripRepository, DriverRepository driverRepository) {
        this.tripRepository = tripRepository;
        this.driverRepository = driverRepository;
    }

    @Override
    public Trip createTrip(TripRequest request) {
        // 1. Tìm tài xế
        Point searchPoint = new Point(request.getPickupLongitude(), request.getPickupLatitude());
        Distance radius = new Distance(2, Metrics.KILOMETERS);
        
        List<Driver> nearbyDrivers = driverRepository.findByIsOnlineTrueAndLocationNear(searchPoint, radius);

        if (nearbyDrivers.isEmpty()) {
            throw new RuntimeException("Rất tiếc, không tìm thấy tài xế nào quanh đây!");
        }

        // 2. Tạo chuyến đi
        Trip newTrip = new Trip();
        
        // Bây giờ file Trip.java đã có hàm này (do viết tay ở bước 1) nên sẽ hết lỗi đỏ
        newTrip.setPickupLocation(new GeoJsonPoint(request.getPickupLongitude(), request.getPickupLatitude()));
        newTrip.setPickupAddress(request.getPickupAddress());

        if (request.getDestinationLongitude() != null && request.getDestinationLatitude() != null) {
            newTrip.setDestinationLocation(new GeoJsonPoint(request.getDestinationLongitude(), request.getDestinationLatitude()));
            newTrip.setDestinationAddress(request.getDestinationAddress());
        }

        // 3. Gán tài xế
        Driver selectedDriver = nearbyDrivers.get(0); 
        newTrip.setDriverId(selectedDriver.getId());
        newTrip.setStatus(TripStatus.DRIVER_ACCEPTED); 
        
        return tripRepository.save(newTrip);
    }

    @Override
    public Trip getTrip(String id) {
        return tripRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Trip not found with id: " + id));
    }
}