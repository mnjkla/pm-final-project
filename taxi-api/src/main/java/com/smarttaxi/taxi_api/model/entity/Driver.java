package com.smarttaxi.taxi_api.model.entity;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexType;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "drivers") // MongoDB dùng @Document
public class Driver {
    
    @Id
    private String id; // ID MongoDB là chuỗi String (ObjectId)

    private String name;
    private String phone;
    private String vehicleType; // BIKE, CAR
    private boolean isOnline;   // Trạng thái nhận cuốc

    // QUAN TRỌNG: Chỉ mục địa lý để tìm xe gần nhất
    // "2dsphere" giúp tính khoảng cách theo mặt cầu trái đất
    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint location;

    // Constructor tiện lợi để tạo nhanh khi test
    public Driver(String name, String phone, double longitude, double latitude) {
        this.name = name;
        this.phone = phone;
        this.isOnline = true;
        this.vehicleType = "BIKE";
        // MongoDB quy định: Kinh độ (Longitude) trước, Vĩ độ (Latitude) sau
        this.location = new GeoJsonPoint(longitude, latitude);
    }
}