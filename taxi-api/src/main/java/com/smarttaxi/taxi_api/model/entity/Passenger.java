package com.smarttaxi.taxi_api.model.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.Data;

@Data
@Document(collection = "passengers")
public class Passenger {
    @Id
    private String id;          // ID của MongoDB (tự sinh)
    private String firebaseId;  // QUAN TRỌNG: Link với Firebase
    private String phoneNumber;
    private String name;
    private String email;
    private String avatarUrl;
    // ... thêm các trường khác như tọa độ, rating...
    private Double latitude;

}