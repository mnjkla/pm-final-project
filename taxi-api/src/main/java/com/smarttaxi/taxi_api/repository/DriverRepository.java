package com.smarttaxi.taxi_api.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.geo.Distance;
import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.repository.MongoRepository;

import com.smarttaxi.taxi_api.model.entity.Driver;

public interface DriverRepository extends MongoRepository<Driver, String> {

    // 1. Tìm theo vị trí (cũ)
    List<Driver> findByLocationNear(Point location, Distance distance);
    
    // 2. Tìm xe online gần đây
    List<Driver> findByIsOnlineTrueAndLocationNear(Point location, Distance distance);

    // 3. FIX LỖI: Thêm hàm tìm theo FirebaseId cho AuthController
    Optional<Driver> findByFirebaseId(String firebaseId);

    // 4. FIX LỖI: Thêm hàm tìm xe có lọc theo Rating cho TripService
    List<Driver> findByIsOnlineTrueAndLocationNearAndRatingGreaterThanEqual(
        Point location, 
        Distance distance, 
        Double minRating
    );
    
}