package com.smarttaxi.taxi_api.model.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexType;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "drivers")
public class Driver {
    
    @Id
    private String id;
    
    // --- Các trường bị thiếu gây lỗi setFirebaseId ---
    private String firebaseId; 
    
    private String name;
    private String phone;
    
    // --- Các trường bị thiếu gây lỗi setVehiclePlate, setVehicleBrand ---
    private String vehicleType;  // BIKE, CAR_4, CAR_7
    private String vehiclePlate; // Biển số
    private String vehicleBrand; // Hãng xe (Honda, Toyota...)

    private boolean isOnline;   

    // --- Các trường dùng cho tính điểm (Scoring) ---
    private Double rating = 5.0;          
    private Double acceptanceRate = 1.0;  
    private Integer totalTrips = 0;       

    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint location;

    // Constructor phục vụ test
    public Driver(String name, String phone, double longitude, double latitude) {
        this.name = name;
        this.phone = phone;
        this.isOnline = true;
        this.vehicleType = "BIKE";
        this.location = new GeoJsonPoint(longitude, latitude);
    }
}