package com.smarttaxi.taxi_api.model.entity;

import com.smarttaxi.taxi_api.model.enums.TripStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "trips")
public class Trip {
    @Id
    private String id;

    private String driverId;    // ID tài xế nhận cuốc
    private String customerId;  // ID khách đặt (nếu có Auth)

    private GeoJsonPoint pickupLocation;      // Tọa độ đón (Lưu dạng GeoJSON để tính toán map)
    private GeoJsonPoint destinationLocation; // Tọa độ đến

    private String pickupAddress;
    private String destinationAddress;

    private Double price;
    private TripStatus status; // SEARCHING, DRIVER_ACCEPTED, ON_TRIP, COMPLETED...

    private LocalDateTime createdAt = LocalDateTime.now();
}