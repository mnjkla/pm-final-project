package com.smarttaxi.taxi_api.model.entity;

import java.time.LocalDateTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.mapping.Document;

import com.smarttaxi.taxi_api.model.enums.TripStatus;

import lombok.Data;
@Data


@Document(collection = "trips")
public class Trip {
    @Id
    private String id;

    private String driverId;
    private String customerId;
    private Integer rating; // 1 đến 5 sao
    private String feedback;

    // Tọa độ
    private GeoJsonPoint pickupLocation;
    private GeoJsonPoint destinationLocation;

    // Địa chỉ chữ
    private String pickupAddress;
    private String destinationAddress;

    // --- THÔNG TIN GIÁ CƯỚC CHI TIẾT (MỚI) ---
    private Double distance;      // Khoảng cách thực tế (km)
    private Double duration;      // Thời gian đi (phút) - dùng tính tiền chờ
    private Double price;         // Tổng tiền chốt cuối cùng
    
    private TripStatus status;

    // Thời gian
    private LocalDateTime createdAt = LocalDateTime.now(); // Thời điểm đặt
    private LocalDateTime startTime; // Thời điểm lên xe (MỚI)
    private LocalDateTime endTime;   // Thời điểm hoàn thành (MỚI)

    public Trip() {}

    // --- BỔ SUNG GETTER/SETTER CHO CÁC TRƯỜNG MỚI ---
    
    // (Giữ nguyên các Getter/Setter cũ của bạn, chỉ thêm phần dưới đây)

    public Double getDistance() { return distance; }
    public void setDistance(Double distance) { this.distance = distance; }

    public Double getDuration() { return duration; }
    public void setDuration(Double duration) { this.duration = duration; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }

    public LocalDateTime getEndTime() { return endTime; }
    public void setEndTime(LocalDateTime endTime) { this.endTime = endTime; }

    // ... (Các Getter/Setter cũ giữ nguyên) ...
    // Note: Nhớ giữ lại Getter/Setter cho price, status, location như file gốc bạn gửi
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