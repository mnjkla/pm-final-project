package com.smarttaxi.taxi_api.model.entity;

import java.time.LocalTime;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "price_configs")
public class PriceConfig {
    @Id
    private String id;
    
    private String vehicleType;     // BIKE, CAR_4, CAR_7
    private Double baseFare;        // Giá mở cửa (VD: 10.000đ)
    private Double pricePerKm;      // Giá mỗi km (VD: 5.000đ)
    private Double surgeMultiplier; // Hệ số nhân (VD: 1.5)
    
    // Khung giờ áp dụng
    private LocalTime startTime;
    private LocalTime endTime;

    // Constructor tiện lợi
    public PriceConfig(String vehicleType, Double baseFare, Double pricePerKm, Double surgeMultiplier, LocalTime start, LocalTime end) {
        this.vehicleType = vehicleType;
        this.baseFare = baseFare;
        this.pricePerKm = pricePerKm;
        this.surgeMultiplier = surgeMultiplier;
        this.startTime = start;
        this.endTime = end;
    }
}