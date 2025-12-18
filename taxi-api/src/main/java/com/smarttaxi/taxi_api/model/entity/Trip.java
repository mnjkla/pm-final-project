package com.smarttaxi.taxi_api.model.entity;

import java.time.LocalDateTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.mapping.Document;

import com.smarttaxi.taxi_api.model.enums.TripStatus;

// XÓA HẾT ANNOTATION CỦA LOMBOK (@Data, @AllArgs...)
@Document(collection = "trips")
public class Trip {
    @Id
    private String id;

    private String driverId;
    private String customerId;

    private GeoJsonPoint pickupLocation;
    private GeoJsonPoint destinationLocation;

    private String pickupAddress;
    private String destinationAddress;

    private Double price;
    private TripStatus status;

    private LocalDateTime createdAt = LocalDateTime.now();

    // --- 1. CONSTRUCTOR RỖNG (Bắt buộc) ---
    public Trip() {}

    // --- 2. GETTERS & SETTERS (Tự viết tay) ---
    // (Phải có đoạn này thì TripServiceImpl mới gọi được hàm .setPickupLocation)

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getDriverId() { return driverId; }
    public void setDriverId(String driverId) { this.driverId = driverId; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public GeoJsonPoint getPickupLocation() { return pickupLocation; }
    public void setPickupLocation(GeoJsonPoint pickupLocation) { this.pickupLocation = pickupLocation; }

    public GeoJsonPoint getDestinationLocation() { return destinationLocation; }
    public void setDestinationLocation(GeoJsonPoint destinationLocation) { this.destinationLocation = destinationLocation; }

    public String getPickupAddress() { return pickupAddress; }
    public void setPickupAddress(String pickupAddress) { this.pickupAddress = pickupAddress; }

    public String getDestinationAddress() { return destinationAddress; }
    public void setDestinationAddress(String destinationAddress) { this.destinationAddress = destinationAddress; }

    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }

    public TripStatus getStatus() { return status; }
    public void setStatus(TripStatus status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}