
package com.smarttaxi.taxi_api.model.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.Data;

@Data
@Document(collection = "customers")
public class Customer {
    @Id
    private String id;
    private String firebaseId; 
    private String name;
    private String phone;
    private String email;
    private String avatarUrl;
}