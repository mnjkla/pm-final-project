package com.smarttaxi.taxi_api.repository;

import java.util.List;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import com.smarttaxi.taxi_api.model.entity.Trip;

@Repository
public interface TripRepository extends MongoRepository<Trip, String> {
    // Bạn có thể thêm các hàm tìm kiếm tùy chỉnh ở đây nếu cần
    // Ví dụ: Tìm chuyến đi đang thực hiện của 1 tài xế
    // List<Trip> findByDriverIdAndStatus(String driverId, TripStatus status);
    List<Trip> findByDriverId(String driverId);
    
}