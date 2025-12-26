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

    // --- 👇 THÊM CÁC TRƯỜNG CÒN THIẾU VÀO ĐÂY 👇 ---
    private String firebaseId;    // Khớp với setFirebaseId
    private String vehiclePlate;  // Khớp với setVehiclePlate
    private String vehicleBrand;  // Khớp với setVehicleBrand
    // --------------------------------------------------

    private String name;
    private String phone;
    private String vehicleType; 
    private boolean isOnline;   
    
    // Đã thêm ở bước trước (nếu chưa có thì thêm luôn)
    private Double rating = 5.0;          
    private Double acceptanceRate = 1.0;

    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint location;

    public Driver(String name, String phone, double longitude, double latitude) {
        this.name = name;
        this.phone = phone;
        this.isOnline = true;
        this.vehicleType = "BIKE";
        this.rating = 5.0;
        this.acceptanceRate = 1.0;
        this.location = new GeoJsonPoint(longitude, latitude);
    }
}